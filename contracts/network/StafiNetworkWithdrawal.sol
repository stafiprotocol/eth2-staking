pragma solidity 0.6.12;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../StafiBase.sol";
import "../interfaces/IStafiEther.sol";
import "../interfaces/pool/IStafiStakingPool.sol";
import "../interfaces/pool/IStafiStakingPoolManager.sol";
import "../interfaces/node/IStafiNodeManager.sol";
import "../interfaces/deposit/IStafiUserDeposit.sol";
import "../interfaces/settings/IStafiNetworkSettings.sol";
import "../interfaces/network/IStafiNetworkWithdrawal.sol";
import "../types/StakingPoolStatus.sol";

// Handles network validator withdrawals
contract StafiNetworkWithdrawal is StafiBase, IStafiNetworkWithdrawal {

    // Libs
    using SafeMath for uint256;

    // Events
    event WithdrawalReceived(address indexed from, uint256 amount, uint256 time);
    event WithdrawalProcessed(address indexed stakingPool, uint256 nodeAmount, uint256 userAmount, uint256 time);

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) public {
        version = 1;
    }

    // Current withdrawal pool balance
    function getBalance() override public view returns (uint256) {
        IStafiEther stafiEther = IStafiEther(getContractAddress("stafiEther"));
        return stafiEther.balanceOf(address(this));
    }

    // Accept a validator withdrawal from the beacon chain
    receive() external payable onlyLatestContract("stafiNetworkWithdrawal", address(this)) {
        // Check deposit amount
        require(msg.value > 0, "Invalid deposit amount");
        // Load contracts
        IStafiEther stafiEther = IStafiEther(getContractAddress("stafiEther"));
        // Transfer ETH to vault
        stafiEther.depositEther{value: msg.value}();
        // Emit withdrawal received event
        emit WithdrawalReceived(msg.sender, msg.value, now);
    }

    // Withdraw a stakingpool
    // Only accepts calls from trusted (oracle) nodes
    // _stakingStartBalance is the validator balance at the time of the user deposit if assigned, or the balance at activation_epoch
    // _stakingEndBalance is the validator balance at withdrawable_epoch
    function withdrawStakingPool(address _stakingPoolAddress, uint256 _stakingStartBalance, uint256 _stakingEndBalance) override external
    onlyLatestContract("stafiNetworkWithdrawal", address(this)) onlyTrustedNode(msg.sender) onlyRegisteredStakingPool(_stakingPoolAddress) {
        // Load contracts
        IStafiNetworkSettings stafiNetworkSettings = IStafiNetworkSettings(getContractAddress("stafiNetworkSettings"));
        // Check settings
        require(stafiNetworkSettings.getProcessWithdrawalsEnabled(), "Processing withdrawals is currently disabled");
        // Check balance
        require(getBalance() >= _stakingEndBalance, "Insufficient withdrawal pool balance");
        // Check withdrawal status
        IStafiStakingPoolManager stafiStakingPoolManager = IStafiStakingPoolManager(getContractAddress("stafiStakingPoolManager"));
        require(!stafiStakingPoolManager.getStakingPoolWithdrawalProcessed(_stakingPoolAddress), "Withdrawal has already been processed for stakingpool");
        // Check stakingpool status
        IStafiStakingPool stakingPool = IStafiStakingPool(_stakingPoolAddress);
        require(stakingPool.getStatus() == StakingPoolStatus.Staking, "Staking pool can only be set as withdrawable while staking");
        // Get submission keys
        bytes32 nodeSubmissionKey = keccak256(abi.encodePacked("stakingpool.withdrawable.submitted.node", msg.sender, _stakingPoolAddress, _stakingStartBalance, _stakingEndBalance));
        bytes32 submissionCountKey = keccak256(abi.encodePacked("stakingpool.withdrawable.submitted.count", _stakingPoolAddress, _stakingStartBalance, _stakingEndBalance));
        // Check & update node submission status
        require(!getBool(nodeSubmissionKey), "Duplicate submission from node");
        setBool(nodeSubmissionKey, true);
        setBool(keccak256(abi.encodePacked("stakingpool.withdrawable.submitted.node", msg.sender, _stakingPoolAddress)), true);
        // Increment submission count
        uint256 submissionCount = getUint(submissionCountKey).add(1);
        setUint(submissionCountKey, submissionCount);
        // Check submission count & set stakingpool withdrawable
        uint256 calcBase = 1 ether;
        IStafiNodeManager stafiNodeManager = IStafiNodeManager(getContractAddress("stafiNodeManager"));
        if (calcBase.mul(submissionCount) >= stafiNodeManager.getTrustedNodeCount().mul(stafiNetworkSettings.getNodeConsensusThreshold())) {
            processWithdrawal(_stakingPoolAddress, _stakingStartBalance, _stakingEndBalance);
        }
    }

    // Process a validator withdrawal from the beacon chain
    // Only accepts calls from trusted (oracle) nodes
    function processWithdrawal(address _stakingPoolAddress, uint256 _stakingStartBalance, uint256 _stakingEndBalance) private {
        // Load contracts
        IStafiNetworkSettings stafiNetworkSettings = IStafiNetworkSettings(getContractAddress("stafiNetworkSettings"));
        IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));
        IStafiStakingPoolManager stafiStakingPoolManager = IStafiStakingPoolManager(getContractAddress("stafiStakingPoolManager"));
        IStafiEther stafiEther = IStafiEther(getContractAddress("stafiEther"));
        IStafiStakingPool stakingPool = IStafiStakingPool(_stakingPoolAddress);

        uint256 nodeAmount = getStakingPoolNodeRewardAmount(
            stafiNetworkSettings.getPlatformFee(),
            stafiNetworkSettings.getNodeFee(),
            stakingPool.getNodeDepositBalance(),
            stakingPool.getUserDepositBalance(),
            _stakingStartBalance,
            _stakingEndBalance
        );
        uint256 userAmount = getStakingPoolUserRewardAmount(
            stafiNetworkSettings.getPlatformFee(),
            stafiNetworkSettings.getNodeFee(),
            stakingPool.getNodeDepositBalance(),
            stakingPool.getUserDepositBalance(),
            _stakingStartBalance,
            _stakingEndBalance
        );
        // Set withdrawal processed status
        stafiStakingPoolManager.setStakingPoolWithdrawalProcessed(_stakingPoolAddress, true);  
        // Withdraw ETH
        if (_stakingEndBalance > 0) {
            // Withdraw
            stafiEther.withdrawEther(_stakingEndBalance);
        }
        // Transfer ETH to node address
        if (nodeAmount > 0) { 
            (bool success,) = stakingPool.getNodeAddress().call{value: nodeAmount}("");
            require(success, "Node ETH balance was not successfully transferred to node operator");
        }
        // Transfer user balance to deposit pool
        if (userAmount > 0) {
            stafiUserDeposit.recycleWithdrawnDeposit{value: userAmount}();
        }
        // Emit withdrawal processed event
        emit WithdrawalProcessed(_stakingPoolAddress, nodeAmount, userAmount, now);
    }

    // Calculate the node reward amount for a stakingpool
    // _startBalance is the validator balance at the time of the user deposit if assigned, or the balance at activation_epoch
    // _endBalance is the validator balance at withdrawable_epoch or a specified epoch
    function getStakingPoolNodeRewardAmount(
        uint256 _platformFee, uint256 _nodeFee, uint256 _nodeDepositBalance, uint256 _userDepositBalance, uint256 _startBalance, uint256 _endBalance
    ) override public pure returns (uint256) {
        // Node reward amount
        uint256 nodeAmount = 0;
        // Calculate node balance at time of user deposit
        uint256 nodeInitialBalance = 0;
        if (_startBalance > _userDepositBalance) {
            nodeInitialBalance = _startBalance.sub(_userDepositBalance);
        }
        // Rewards earned
        if (_endBalance > _startBalance) {
            // Calculate rewards earned
            uint256 rewards = _endBalance.sub(_startBalance);
            // Calculate platform commission
            uint256 calcBase = 1 ether;
            uint256 platformCommission = rewards.mul(_platformFee).div(calcBase);
            rewards = rewards.sub(platformCommission);
            // Calculate node share of rewards
            uint256 nodeShare = rewards.mul(nodeInitialBalance).div(_startBalance);
            rewards = rewards.sub(nodeShare);
            // Calculate node commission on user share of rewards
            uint256 nodeCommission = rewards.mul(_nodeFee).div(calcBase);
            // Update node reward amount
            nodeAmount = _nodeDepositBalance.add(nodeShare).add(nodeCommission);
        }
        // No rewards earned
        else {
            // Deduct losses from node balance
            if (_startBalance < _nodeDepositBalance.add(_endBalance)) {
                nodeAmount = _nodeDepositBalance.add(_endBalance).sub(_startBalance);
            }
        }
        // Return
        return nodeAmount;
    }

    // Calculate the user reward amount for a stakingpool
    // _startBalance is the validator balance at the time of the user deposit if assigned, or the balance at activation_epoch
    // _endBalance is the validator balance at withdrawable_epoch or a specified epoch
    function getStakingPoolUserRewardAmount(
        uint256 _platformFee, uint256 _nodeFee, uint256 _nodeDepositBalance, uint256 _userDepositBalance, uint256 _startBalance, uint256 _endBalance
    ) override public pure returns (uint256) {
        // User reward amount
        uint256 userAmount = 0;
        // Calculate node balance at time of user deposit
        uint256 nodeInitialBalance = 0;
        if (_startBalance > _userDepositBalance) {
            nodeInitialBalance = _startBalance.sub(_userDepositBalance);
        }
        // Rewards earned
        if (_endBalance > _startBalance) {
            // Calculate rewards earned
            uint256 rewards = _endBalance.sub(_startBalance);
            // Calculate platform commission
            uint256 calcBase = 1 ether;
            uint256 platformCommission = rewards.mul(_platformFee).div(calcBase);
            rewards = rewards.sub(platformCommission);
            // Calculate node share of rewards
            uint256 nodeShare = rewards.mul(nodeInitialBalance).div(_startBalance);
            rewards = rewards.sub(nodeShare);
            // Calculate node commission on user share of rewards
            uint256 nodeCommission = rewards.mul(_nodeFee).div(calcBase);
            // Update user reward amount
            userAmount = _userDepositBalance.add(rewards).sub(nodeCommission);
        }
        // No rewards earned
        else {
            // Deduct losses from node balance
            if (_startBalance < _nodeDepositBalance.add(_endBalance)) {
                uint256 nodeAmount = _nodeDepositBalance.add(_endBalance).sub(_startBalance);
                userAmount = _endBalance.sub(nodeAmount);
            }
        }
        // Return
        return userAmount;
    }

}
