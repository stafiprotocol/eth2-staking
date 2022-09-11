pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/storage/IStafiStorage.sol";
import "../interfaces/eth/IDepositContract.sol";
import "../interfaces/deposit/IStafiUserDeposit.sol";
import "../interfaces/pool/IStafiStakingPool.sol";
import "../interfaces/settings/IStafiNetworkSettings.sol";
import "../interfaces/pool/IStafiStakingPoolManager.sol";
import "../interfaces/pool/IStafiStakingPoolQueue.sol";
import "../interfaces/settings/IStafiStakingPoolSettings.sol";
import "../interfaces/node/IStafiNodeManager.sol";
import "../types/DepositType.sol";
import "../types/StakingPoolStatus.sol";
import "./StafiStakingPoolStorage.sol";

// An individual staking pool
contract StafiStakingPoolDelegate is StafiStakingPoolStorage, IStafiStakingPool {
    // Libs
    using SafeMath for uint256;

    // Events
    event StatusUpdated(uint8 indexed status, uint256 time);
    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event EtherRefunded(address indexed node, address indexed stakingPool, uint256 amount, uint256 time);
    event EtherWithdrawn(address indexed to, uint256 amount, uint256 time);
    event VoteWithdrawalCredentials(address node);

    // Status getters
    function getStatus() override external view returns (StakingPoolStatus) { return status; }
    function getStatusBlock() override external view returns (uint256) { return statusBlock; }
    function getStatusTime() override external view returns (uint256) { return statusTime; }
    function getWithdrawalCredentialsMatch() override external view returns (bool) { return withdrawalCredentialsMatch; }

    // Deposit type getter
    function getDepositType() override external view returns (DepositType) { return depositType; }

    // Node detail getters
    function getNodeAddress() override external view returns (address) { return nodeAddress; }
    function getNodeFee() override external view returns (uint256) { return nodeFee; }
    function getNodeDepositBalance() override external view returns (uint256) { return nodeDepositBalance; }
    function getNodeDepositAssigned() override external view returns (bool) { return nodeDepositAssigned; }
    function getNodeRefundBalance() override external view returns (uint256) { return nodeRefundBalance; }
    function getNodeCommonlyRefunded() override external view returns (bool) { return nodeCommonlyRefunded; }
    function getNodeTrustedRefunded() override external view returns (bool) { return nodeTrustedRefunded; }

    // User deposit detail getters
    function getUserDepositBalance() override external view returns (uint256) { return userDepositBalance; }
    function getUserDepositAssigned() override external view returns (bool) { return userDepositAssigned; }
    function getUserDepositAssignedTime() override external view returns (uint256) { return userDepositAssignedTime; }

    // Platform detail getters
    function getPlatformDepositBalance() override external view returns (uint256) { return platformDepositBalance; }

    // initialise
    function initialise(address _nodeAddress, DepositType _depositType) override external onlyUninitialised {
        // Check parameters
        require(_nodeAddress != address(0x0), "invalid node address");
        require(_depositType != DepositType.None, "invalid deposit type");
        // Set status
        setStatus(StakingPoolStatus.Initialized);
        // Set details
        depositType = _depositType;
        nodeAddress = _nodeAddress;
        // Get settings
        nodeFee = StafiNetworkSettings().getNodeFee();
        storageState = StorageState.Initialised;
    }

    // Prevent direct calls to this contract
    modifier onlyInitialised() {
        require(storageState == StorageState.Initialised, "Storage state not initialised");
        _;
    }

    modifier onlyUninitialised() {
        require(storageState == StorageState.Uninitialised, "Storage state already initialised");
        _;
    }

    // Only allow access from the owning node address
    modifier onlyStakingPoolOwner(address _nodeAddress) {
        require(_nodeAddress == nodeAddress, "invalid owner");
        _;
    }

    // Only allow access from the latest version of the specified contract
    modifier onlyLatestContract(string memory _contractName, address _contractAddress) {
        require(_contractAddress == getContractAddress(_contractName), "invalid or outdated");
        _;
    }
    
    // Throws if called by any sender that isn't a trusted node
    modifier onlyTrustedNode(address _nodeAddress) {
        require(stafiStorage.getBool(keccak256(abi.encodePacked("node.trusted", _nodeAddress))), "invalid trusted node");
        _;
    }

    // Get the address of a network contract
    function getContractAddress(string memory _contractName) private view returns (address) {
        return stafiStorage.getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
    }

    function StafiStakingPoolSettings() private view returns (IStafiStakingPoolSettings) {
        return IStafiStakingPoolSettings(getContractAddress("stafiStakingPoolSettings"));
    }

    function StafiStakingPoolManager() private view returns (IStafiStakingPoolManager) {
        return IStafiStakingPoolManager(getContractAddress("stafiStakingPoolManager"));
    }

    function StafiNetworkSettings() private view returns (IStafiNetworkSettings) {
        return IStafiNetworkSettings(getContractAddress("stafiNetworkSettings"));
    }

    function EthDeposit() private view returns (IDepositContract) {
        return IDepositContract(getContractAddress("ethDeposit"));
    }

    // Assign the node deposit to the staking pool
    // Only accepts calls from the StafiNodeDeposit contract
    function nodeDeposit(bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot) override external payable onlyLatestContract("stafiNodeDeposit", msg.sender) onlyInitialised {
        // Check current status & node deposit status
        require(status == StakingPoolStatus.Initialized, "status != initialized");
        require(!nodeDepositAssigned, "assigned error");
        // Load contracts
        IStafiStakingPoolManager stafiStakingPoolManager = StafiStakingPoolManager();
        // Check deposit amount
        uint256 depositNodeAmount =  StafiStakingPoolSettings().getDepositNodeAmount(depositType);
        require(msg.value == depositNodeAmount, "invalid node deposit amount");
        // Update node deposit details
        nodeDepositBalance = msg.value;
        nodeDepositAssigned = true;
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);

        // Check validator pubkey is not in use
        require(stafiStakingPoolManager.getStakingPoolByPubkey(_validatorPubkey) == address(0x0), "pubkey is used");
        // check pubkey in superNodes/lightNodes
        require(!stafiStorage.getBool(keccak256(abi.encodePacked("superNode.pubkey.exists", _validatorPubkey))), "super node pubkey exists");
        // check pubkey of lightNodes
        require(!stafiStorage.getBool(keccak256(abi.encodePacked("lightNode.pubkey.exists", _validatorPubkey))), "light Node pubkey exists");

        // Set stakingPool pubkey
        stafiStakingPoolManager.setStakingPoolPubkey(_validatorPubkey);

        preStake(_validatorPubkey, _validatorSignature, _depositDataRoot);
        
    }

    // Assign user deposited ETH to the staking pool and mark it as prelaunch
    function userDeposit() override external payable onlyLatestContract("stafiUserDeposit", msg.sender) onlyInitialised {
        // Check current status & user deposit status
        // The user deposit can only be assigned while initialized, in prelaunch, or staking
        require(status >= StakingPoolStatus.Initialized && status <= StakingPoolStatus.Staking, "status unmatch");
        require(!userDepositAssigned, "assigned");
        // Check deposit amount
        require(msg.value == StafiStakingPoolSettings().getDepositUserAmount(depositType), "invalid user deposit amount");
        // Update user deposit details
        userDepositBalance = msg.value;
        userDepositAssigned = true;
        userDepositAssignedTime = block.timestamp;
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
        // Progress initialized staking pool to prelaunch
        if (status == StakingPoolStatus.Initialized) { setStatus(StakingPoolStatus.Prelaunch); }
    }

    // Progress the staking pool to staking, sending its ETH deposit to the VRC
    // Only accepts calls from the staking pool owner (node)
    function stake(bytes calldata _validatorSignature, bytes32 _depositDataRoot) override external onlyLatestContract("stafiNodeDeposit", msg.sender) onlyInitialised{
        // Check current status
        require(status == StakingPoolStatus.Prelaunch, "status unmatch");
        // Check withdrawCredentials match
        require(withdrawalCredentialsMatch, "invalid withdraw credentials");
        // Check staking pool balance
        require(address(this).balance >= userDepositBalance, "Insufficient balance");
        // Send staking deposit to casper
        EthDeposit().deposit{value: userDepositBalance}(StafiStakingPoolManager().getStakingPoolPubkey(address(this)),
        StafiNetworkSettings().getWithdrawalCredentials(), _validatorSignature, _depositDataRoot);
        // Progress to staking
        setStatus(StakingPoolStatus.Staking);
    }


    // Stakes some ETH into the deposit contract to set withdrawal credentials to this contract
    function preStake(bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot) internal {
        // Check stakingPool balance
        require(address(this).balance >= nodeDepositBalance, "Insufficient balance");
        // Get withdrawal credentials
        bytes memory withdrawalCredentials = StafiNetworkSettings().getWithdrawalCredentials();
        // Send staking deposit to casper
        EthDeposit().deposit{value : nodeDepositBalance}(_validatorPubkey, withdrawalCredentials, _validatorSignature, _depositDataRoot);
    }

    // Only accepts calls from trusted (oracle) nodes
    function voteWithdrawCredentials() override external onlyTrustedNode(msg.sender) onlyInitialised {
        // Check & update node vote status
        require(!memberVotes[msg.sender], "Member has already voted to withdrawCredentials");
        memberVotes[msg.sender] = true;
        // Increment votes count
        totalVotes = totalVotes.add(1);
        // Emit event
        emit VoteWithdrawalCredentials(msg.sender);
        // Check submission count & update network balances
        uint256 calcBase = 1 ether;
        IStafiNodeManager stafiNodeManager = IStafiNodeManager(getContractAddress("stafiNodeManager"));
        if (calcBase.mul(totalVotes) >= stafiNodeManager.getTrustedNodeCount().mul(StafiNetworkSettings().getNodeConsensusThreshold()) && !withdrawalCredentialsMatch) {
            withdrawalCredentialsMatch = true;
        }
    }

    // Progress the refund
    // Only accepts calls from the staking pool owner (node)
    function refund() override external onlyStakingPoolOwner(msg.sender) {
        // Check current status
        // The staking pool can only be refunded while staking
        require(status == StakingPoolStatus.Staking, "status unmatch");
        require(!nodeTrustedRefunded, "already refunded");

        address poolAddress = address(this);
        uint256 calcBase = 1 ether;
        if (StafiStakingPoolSettings().getStakingPoolTrustedRefundedEnabled(poolAddress)) {
            uint256 totalNodeDepositBalance = nodeDepositBalance;
            if (nodeCommonlyRefunded) {
                totalNodeDepositBalance = nodeDepositBalance.add(nodeRefundBalance);
            }
            nodeRefundBalance = totalNodeDepositBalance.mul(StafiNetworkSettings().getNodeTrustedRefundRatio()).div(calcBase);
            platformDepositBalance = nodeRefundBalance;
            nodeDepositBalance = totalNodeDepositBalance.sub(nodeRefundBalance);
            nodeTrustedRefunded = true;
        } else {
            require(!nodeCommonlyRefunded, "already refunded commonly");
            require(StafiStakingPoolSettings().getStakingPoolRefundedEnabled(poolAddress), "refunded not enabled");

            nodeRefundBalance = nodeDepositBalance.mul(StafiNetworkSettings().getNodeRefundRatio()).div(calcBase);
            platformDepositBalance = nodeRefundBalance;
            nodeDepositBalance = nodeDepositBalance.sub(nodeRefundBalance);
            nodeCommonlyRefunded = true;   
        }
        // Emit ether refunded event
        emit EtherRefunded(msg.sender, poolAddress, nodeRefundBalance, block.timestamp);
    }

    // Dissolve the staking pool, returning user deposited ETH to the deposit pool
    // Only accepts calls from the staking pool owner (node), or from any address if timed out
    function dissolve() override external onlyInitialised{
        // Check current status
        // The staking pool can only be dissolved while initialized or in prelaunch
        require(status == StakingPoolStatus.Initialized || status == StakingPoolStatus.Prelaunch, "status unmatch");
        // Load contracts
        IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));
        // Check if being dissolved by staking pool owner or staking pool is timed out
        require(
            msg.sender == nodeAddress ||
            (status == StakingPoolStatus.Prelaunch && block.number.sub(statusBlock) >= StafiStakingPoolSettings().getLaunchTimeout()),
            "must owner or timed out"
        );
        // Remove staking pool from queue
        if (!userDepositAssigned) { IStafiStakingPoolQueue(getContractAddress("stafiStakingPoolQueue")).removeStakingPool(); }
        // Transfer user balance to deposit pool
        if (userDepositBalance > 0) {
            userDepositBalance = 0;
            // Transfer
            stafiUserDeposit.recycleDissolvedDeposit{value: userDepositBalance}();
            // Emit ether withdrawn event
            emit EtherWithdrawn(address(stafiUserDeposit), userDepositBalance, block.timestamp);
        }
        // Progress to dissolved
        setStatus(StakingPoolStatus.Dissolved);
    }

    // Withdraw node balances from the staking pool and close it
    // Only accepts calls from the staking pool owner (node)
    function close() override external onlyStakingPoolOwner(msg.sender) onlyInitialised{
        // Check current status
        // The staking pool can only be closed while dissolved
        require(status == StakingPoolStatus.Dissolved, "status unmatch");
        // Transfer node balance to node operator
        uint256 nodeBalance = nodeDepositBalance;
        if (nodeBalance > 0) {
            // Update node balances
            nodeDepositBalance = 0;
            // Transfer balance
            (bool success,) = nodeAddress.call{value: nodeBalance}("");
            require(success, "transferr failed");
            // Emit ether withdrawn event
            emit EtherWithdrawn(nodeAddress, nodeBalance, block.timestamp);
        }
        // Destroy staking pool
        destroy();
    }

    // Set the staking pool's current status
    function setStatus(StakingPoolStatus _status) private {
        // Update status
        status = _status;
        statusBlock = block.number;
        statusTime = block.timestamp;
        // Emit status updated event
        emit StatusUpdated(uint8(_status), block.timestamp);
    }

    // Destroy the staking pool
    function destroy() private {
        // Destroy staking pool
        IStafiStakingPoolManager stafiStakingPoolManager = StafiStakingPoolManager();
        stafiStakingPoolManager.destroyStakingPool();
        // Self destruct & send any remaining ETH to stafiEther
        selfdestruct(payable(getContractAddress("stafiEther")));
    }

}
