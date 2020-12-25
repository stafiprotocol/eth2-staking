pragma solidity 0.6.12;

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
import "../types/DepositType.sol";
import "../types/StakingPoolStatus.sol";

// An individual staking pool
contract StafiStakingPool is IStafiStakingPool {

    // Libs
    using SafeMath for uint256;

    // Main storage contract
    IStafiStorage stafiStorage = IStafiStorage(0);

    // Status
    StakingPoolStatus private status;
    uint256 private statusBlock;
    uint256 private statusTime;

    // Deposit type
    DepositType private depositType;

    // Node details
    address private nodeAddress;
    uint256 private nodeFee;
    uint256 private nodeDepositBalance;
    bool private nodeDepositAssigned;

    uint256 private nodeRefundBalance;
    bool private nodeCommonlyRefunded;
    bool private nodeTrustedRefunded;

    // User deposit details
    uint256 private userDepositBalance;
    bool private userDepositAssigned;
    uint256 private userDepositAssignedTime;

    // Platform details
    uint256 private platformDepositBalance;

    // Events
    event StatusUpdated(uint8 indexed status, uint256 time);
    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event EtherRefunded(address indexed from, uint256 amount, uint256 time);
    event EtherWithdrawn(address indexed to, uint256 amount, uint256 time);

    // Status getters
    function getStatus() override public view returns (StakingPoolStatus) { return status; }
    function getStatusBlock() override public view returns (uint256) { return statusBlock; }
    function getStatusTime() override public view returns (uint256) { return statusTime; }

    // Deposit type getter
    function getDepositType() override public view returns (DepositType) { return depositType; }

    // Node detail getters
    function getNodeAddress() override public view returns (address) { return nodeAddress; }
    function getNodeFee() override public view returns (uint256) { return nodeFee; }
    function getNodeDepositBalance() override public view returns (uint256) { return nodeDepositBalance; }
    function getNodeDepositAssigned() override public view returns (bool) { return nodeDepositAssigned; }
    function getNodeRefundBalance() override public view returns (uint256) { return nodeRefundBalance; }
    function getNodeCommonlyRefunded() override public view returns (bool) { return nodeCommonlyRefunded; }
    function getNodeTrustedRefunded() override public view returns (bool) { return nodeTrustedRefunded; }

    // User deposit detail getters
    function getUserDepositBalance() override public view returns (uint256) { return userDepositBalance; }
    function getUserDepositAssigned() override public view returns (bool) { return userDepositAssigned; }
    function getUserDepositAssignedTime() override public view returns (uint256) { return userDepositAssignedTime; }

    // Platform detail getters
    function getPlatformDepositBalance() override public view returns (uint256) { return platformDepositBalance; }

    // Construct
    constructor(address _stafiStorageAddress, address _nodeAddress, DepositType _depositType) public {
        // Check parameters
        require(_stafiStorageAddress != address(0x0), "Invalid storage address");
        require(_nodeAddress != address(0x0), "Invalid node address");
        require(_depositType != DepositType.None, "Invalid deposit type");
        // Initialise stafiStorage
        stafiStorage = IStafiStorage(_stafiStorageAddress);
        // Set status
        setStatus(StakingPoolStatus.Initialized);
        // Set details
        depositType = _depositType;
        nodeAddress = _nodeAddress;
        // Get settings
        IStafiNetworkSettings stafiNetworkSettings = IStafiNetworkSettings(getContractAddress("stafiNetworkSettings"));
        nodeFee = stafiNetworkSettings.getNodeFee();
    }

    // Only allow access from the owning node address
    modifier onlyStakingPoolOwner(address _nodeAddress) {
        require(_nodeAddress == nodeAddress, "Invalid staking pool owner");
        _;
    }

    // Only allow access from the latest version of the specified contract
    modifier onlyLatestContract(string memory _contractName, address _contractAddress) {
        require(_contractAddress == getContractAddress(_contractName), "Invalid or outdated contract");
        _;
    }

    // Get the address of a network contract
    function getContractAddress(string memory _contractName) private view returns (address) {
        return stafiStorage.getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
    }

    // Assign the node deposit to the staking pool
    // Only accepts calls from the StafiNodeDeposit contract
    function nodeDeposit() override external payable onlyLatestContract("stafiNodeDeposit", msg.sender) {
        // Check current status & node deposit status
        require(status == StakingPoolStatus.Initialized, "The node deposit can only be assigned while initialized");
        require(!nodeDepositAssigned, "The node deposit has already been assigned");
        // Load contracts
        IStafiStakingPoolSettings stafiStakingPoolSettings = IStafiStakingPoolSettings(getContractAddress("stafiStakingPoolSettings"));
        // Check deposit amount
        require(msg.value == stafiStakingPoolSettings.getDepositNodeAmount(depositType), "Invalid node deposit amount");
        // Update node deposit details
        nodeDepositBalance = msg.value;
        nodeDepositAssigned = true;
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, now);
    }

    // Assign user deposited ETH to the staking pool and mark it as prelaunch
    function userDeposit() override external payable onlyLatestContract("stafiUserDeposit", msg.sender) {
        // Check current status & user deposit status
        require(status >= StakingPoolStatus.Initialized && status <= StakingPoolStatus.Staking, "The user deposit can only be assigned while initialized, in prelaunch, or staking");
        require(!userDepositAssigned, "The user deposit has already been assigned");
        // Load contracts
        IStafiStakingPoolSettings stafiStakingPoolSettings = IStafiStakingPoolSettings(getContractAddress("stafiStakingPoolSettings"));
        // Check deposit amount
        require(msg.value == stafiStakingPoolSettings.getDepositUserAmount(depositType), "Invalid user deposit amount");
        // Update user deposit details
        userDepositBalance = msg.value;
        userDepositAssigned = true;
        userDepositAssignedTime = now;
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, now);
        // Progress initialized staking pool to prelaunch
        if (status == StakingPoolStatus.Initialized) { setStatus(StakingPoolStatus.Prelaunch); }
    }

    // Progress the staking pool to staking, sending its ETH deposit to the VRC
    // Only accepts calls from the staking pool owner (node)
    function stake(bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot) override external onlyStakingPoolOwner(msg.sender) {
        // Check current status
        require(status == StakingPoolStatus.Prelaunch, "The staking pool can only begin staking while in prelaunch");
        // Load contracts
        IDepositContract ethDeposit = IDepositContract(getContractAddress("ethDeposit"));
        IStafiStakingPoolManager stafiStakingPoolManager = IStafiStakingPoolManager(getContractAddress("stafiStakingPoolManager"));
        IStafiStakingPoolSettings stafiStakingPoolSettings = IStafiStakingPoolSettings(getContractAddress("stafiStakingPoolSettings"));
        IStafiNetworkSettings stafiNetworkSettings = IStafiNetworkSettings(getContractAddress("stafiNetworkSettings"));
        // Get launch amount
        uint256 launchAmount = stafiStakingPoolSettings.getLaunchBalance();
        // Check staking pool balance
        require(address(this).balance >= launchAmount, "Insufficient balance to begin staking");
        // Check validator pubkey is not in use
        require(stafiStakingPoolManager.getStakingPoolByPubkey(_validatorPubkey) == address(0x0), "Validator pubkey is already in use");
        // Send staking deposit to casper
        ethDeposit.deposit{value: launchAmount}(_validatorPubkey, stafiNetworkSettings.getWithdrawalCredentials(), _validatorSignature, _depositDataRoot);
        // Set staking pool pubkey
        stafiStakingPoolManager.setStakingPoolPubkey(_validatorPubkey);
        // Progress to staking
        setStatus(StakingPoolStatus.Staking);
    }

    // Progress the refund
    // Only accepts calls from the staking pool owner (node)
    function refund() override external onlyStakingPoolOwner(msg.sender) {
        // Check current status
        require(status == StakingPoolStatus.Staking, "The staking pool can only be refunded while staking");
        require(!nodeTrustedRefunded, "The staking pool has already been refunded");
        // Load contracts
        IStafiStakingPoolSettings stafiStakingPoolSettings = IStafiStakingPoolSettings(getContractAddress("stafiStakingPoolSettings"));
        IStafiNetworkSettings stafiNetworkSettings = IStafiNetworkSettings(getContractAddress("stafiNetworkSettings"));

        address poolAddress = address(this);
        uint256 calcBase = 1 ether;
        if (stafiStakingPoolSettings.getStakingPoolTrustedRefundedEnabled(poolAddress)) {
            uint256 totalNodeDepositBalance = nodeDepositBalance;
            if (nodeCommonlyRefunded) {
                totalNodeDepositBalance = nodeDepositBalance.add(nodeRefundBalance);
            }
            nodeRefundBalance = totalNodeDepositBalance.mul(stafiNetworkSettings.getNodeTrustedRefundRatio()).div(calcBase);
            platformDepositBalance = nodeRefundBalance;
            nodeDepositBalance = totalNodeDepositBalance.sub(nodeRefundBalance);
            nodeTrustedRefunded = true;
        } else {
            require(!nodeCommonlyRefunded, "The staking pool has already been refunded commonly");
            require(stafiStakingPoolSettings.getStakingPoolRefundedEnabled(poolAddress), "The staking pool can only be refunded after being enabled");

            nodeRefundBalance = nodeDepositBalance.mul(stafiNetworkSettings.getNodeRefundRatio()).div(calcBase);
            platformDepositBalance = nodeRefundBalance;
            nodeDepositBalance = nodeDepositBalance.sub(nodeRefundBalance);
            nodeCommonlyRefunded = true;   
        }
        // Emit ether refunded event
        emit EtherRefunded(msg.sender, nodeRefundBalance, now);
    }

    // Dissolve the staking pool, returning user deposited ETH to the deposit pool
    // Only accepts calls from the staking pool owner (node), or from any address if timed out
    function dissolve() override external {
        // Check current status
        require(status == StakingPoolStatus.Initialized || status == StakingPoolStatus.Prelaunch, "The staking pool can only be dissolved while initialized or in prelaunch");
        // Load contracts
        IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));
        IStafiStakingPoolQueue stafiStakingPoolQueue = IStafiStakingPoolQueue(getContractAddress("stafiStakingPoolQueue"));
        IStafiStakingPoolSettings stafiStakingPoolSettings = IStafiStakingPoolSettings(getContractAddress("stafiStakingPoolSettings"));
        // Check if being dissolved by staking pool owner or staking pool is timed out
        require(
            msg.sender == nodeAddress ||
            (status == StakingPoolStatus.Prelaunch && block.number.sub(statusBlock) >= stafiStakingPoolSettings.getLaunchTimeout()),
            "The staking pool can only be dissolved by its owner unless it has timed out"
        );
        // Remove staking pool from queue
        if (!userDepositAssigned) { stafiStakingPoolQueue.removeStakingPool(); }
        // Transfer user balance to deposit pool
        if (userDepositBalance > 0) {
            // Transfer
            stafiUserDeposit.recycleDissolvedDeposit{value: userDepositBalance}();
            userDepositBalance = 0;
            // Emit ether withdrawn event
            emit EtherWithdrawn(address(stafiUserDeposit), userDepositBalance, now);
        }
        // Progress to dissolved
        setStatus(StakingPoolStatus.Dissolved);
    }

    // Withdraw node balances from the staking pool and close it
    // Only accepts calls from the staking pool owner (node)
    function close() override external onlyStakingPoolOwner(msg.sender) {
        // Check current status
        require(status == StakingPoolStatus.Dissolved, "The staking pool can only be closed while dissolved");
        // Transfer node balance to node operator
        uint256 nodeBalance = nodeDepositBalance;
        if (nodeBalance > 0) {
            // Update node balances
            nodeDepositBalance = 0;
            // Transfer balance
            (bool success,) = nodeAddress.call{value: nodeBalance}("");
            require(success, "Node ETH balance was not successfully transferred to node operator");
            // Emit ether withdrawn event
            emit EtherWithdrawn(nodeAddress, nodeBalance, now);
        }
        // Destroy staking pool
        destroy();
    }

    // Set the staking pool's current status
    function setStatus(StakingPoolStatus _status) private {
        // Update status
        status = _status;
        statusBlock = block.number;
        statusTime = now;
        // Emit status updated event
        emit StatusUpdated(uint8(_status), now);
    }

    // Destroy the staking pool
    function destroy() private {
        // Destroy staking pool
        IStafiStakingPoolManager stafiStakingPoolManager = IStafiStakingPoolManager(getContractAddress("stafiStakingPoolManager"));
        stafiStakingPoolManager.destroyStakingPool();
        // Self destruct & send any remaining ETH to stafiEther
        selfdestruct(payable(getContractAddress("stafiEther")));
    }

}
