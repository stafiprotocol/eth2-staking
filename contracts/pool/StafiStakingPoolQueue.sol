pragma solidity 0.6.12;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../StafiBase.sol";
import "../interfaces/pool/IStafiStakingPool.sol";
import "../interfaces/pool/IStafiStakingPoolQueue.sol";
import "../interfaces/settings/IStafiStakingPoolSettings.sol";
import "../interfaces/storage/IAddressQueueStorage.sol";
import "../types/DepositType.sol";

// StakingPool queueing for deposit assignment
contract StafiStakingPoolQueue is StafiBase, IStafiStakingPoolQueue {

    // Libs
    using SafeMath for uint256;

    // Events
    event StakingPoolEnqueued(address indexed stakingPool, bytes32 indexed queueId, uint256 time);
    event StakingPoolDequeued(address indexed stakingPool, bytes32 indexed queueId, uint256 time);
    event StakingPoolRemoved(address indexed stakingPool, bytes32 indexed queueId, uint256 time);

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) public {
        version = 1;
    }

    // Get the total combined length of the queues
    function getTotalLength() override public view returns (uint256) {
        return (
            getLength(DepositType.FOUR)
        ).add(
            getLength(DepositType.EIGHT)
        ).add(
            getLength(DepositType.TWELVE)
        ).add(
            getLength(DepositType.SIXTEEN)
        );
    }

    // Get the length of a queue
    // Returns 0 for invalid queues
    function getLength(DepositType _depositType) override public view returns (uint256) {
        if (_depositType == DepositType.FOUR) { return getLength("stakingpools.available.four"); }
        if (_depositType == DepositType.EIGHT) { return getLength("stakingpools.available.eight"); }
        if (_depositType == DepositType.TWELVE) { return getLength("stakingpools.available.twelve"); }
        if (_depositType == DepositType.SIXTEEN) { return getLength("stakingpools.available.sixteen"); }
        return 0;
    }
    function getLength(string memory _queueId) private view returns (uint256) {
        IAddressQueueStorage addressQueueStorage = IAddressQueueStorage(getContractAddress("addressQueueStorage"));
        return addressQueueStorage.getLength(keccak256(abi.encodePacked(_queueId)));
    }

    // Get the total combined capacity of the queues
    function getTotalCapacity() override public view returns (uint256) {
        IStafiStakingPoolSettings stafiStakingPoolSettings = IStafiStakingPoolSettings(getContractAddress("stafiStakingPoolSettings"));
        return (
            getLength(DepositType.FOUR).mul(stafiStakingPoolSettings.getDepositUserAmount(DepositType.FOUR))
        ).add(
            getLength(DepositType.EIGHT).mul(stafiStakingPoolSettings.getDepositUserAmount(DepositType.EIGHT))
        ).add(
            getLength(DepositType.TWELVE).mul(stafiStakingPoolSettings.getDepositUserAmount(DepositType.TWELVE))
        ).add(
            getLength(DepositType.SIXTEEN).mul(stafiStakingPoolSettings.getDepositUserAmount(DepositType.SIXTEEN))
        );
    }

    // Get the total effective capacity of the queues (used in node demand calculation)
    function getEffectiveCapacity() override public view returns (uint256) {
        IStafiStakingPoolSettings stafiStakingPoolSettings = IStafiStakingPoolSettings(getContractAddress("stafiStakingPoolSettings"));
        return (
            getLength(DepositType.FOUR).mul(stafiStakingPoolSettings.getDepositUserAmount(DepositType.FOUR))
        ).add(
            getLength(DepositType.EIGHT).mul(stafiStakingPoolSettings.getDepositUserAmount(DepositType.EIGHT))
        ).add(
            getLength(DepositType.TWELVE).mul(stafiStakingPoolSettings.getDepositUserAmount(DepositType.TWELVE))
        ).add(
            getLength(DepositType.SIXTEEN).mul(stafiStakingPoolSettings.getDepositUserAmount(DepositType.SIXTEEN))
        );
    }

    // Get the capacity of the next available staking pool
    // Returns 0 if no stakingpools are available
    function getNextCapacity() override public view returns (uint256) {
        IStafiStakingPoolSettings stafiStakingPoolSettings = IStafiStakingPoolSettings(getContractAddress("stafiStakingPoolSettings"));
        if (getLength(DepositType.FOUR) > 0) { return stafiStakingPoolSettings.getDepositUserAmount(DepositType.FOUR); }
        if (getLength(DepositType.EIGHT) > 0) { return stafiStakingPoolSettings.getDepositUserAmount(DepositType.EIGHT); }
        if (getLength(DepositType.TWELVE) > 0) { return stafiStakingPoolSettings.getDepositUserAmount(DepositType.TWELVE); }
        if (getLength(DepositType.SIXTEEN) > 0) { return stafiStakingPoolSettings.getDepositUserAmount(DepositType.SIXTEEN); }
        return 0;
    }

    // Add a staking pool to the end of the appropriate queue
    // Only accepts calls from the StafiStakingPoolManager contract
    function enqueueStakingPool(DepositType _depositType, address _stakingPool) override external onlyLatestContract("stafiStakingPoolQueue", address(this)) onlyLatestContract("stafiStakingPoolManager", msg.sender) {
        if (_depositType == DepositType.FOUR) { return enqueueStakingPool("stakingpools.available.four", _stakingPool); }
        if (_depositType == DepositType.EIGHT) { return enqueueStakingPool("stakingpools.available.eight", _stakingPool); }
        if (_depositType == DepositType.TWELVE) { return enqueueStakingPool("stakingpools.available.twelve", _stakingPool); }
        if (_depositType == DepositType.SIXTEEN) { return enqueueStakingPool("stakingpools.available.sixteen", _stakingPool); }
        require(false, "Invalid staking pool deposit type");
    }
    function enqueueStakingPool(string memory _queueId, address _stakingPool) private {
        // Enqueue
        IAddressQueueStorage addressQueueStorage = IAddressQueueStorage(getContractAddress("addressQueueStorage"));
        addressQueueStorage.enqueueItem(keccak256(abi.encodePacked(_queueId)), _stakingPool);
        // Emit enqueued event
        emit StakingPoolEnqueued(_stakingPool, keccak256(abi.encodePacked(_queueId)), now);
    }

    // Remove the first available staking pool from the highest priority queue and return its address
    // Only accepts calls from the StafiUserDeposit contract
    function dequeueStakingPool() override external onlyLatestContract("stafiStakingPoolQueue", address(this)) onlyLatestContract("stafiUserDeposit", msg.sender) returns (address) {
        if (getLength(DepositType.FOUR) > 0) { return dequeueStakingPool("stakingpools.available.four"); }
        if (getLength(DepositType.EIGHT) > 0) { return dequeueStakingPool("stakingpools.available.eight"); }
        if (getLength(DepositType.TWELVE) > 0) { return dequeueStakingPool("stakingpools.available.twelve"); }
        if (getLength(DepositType.SIXTEEN) > 0) { return dequeueStakingPool("stakingpools.available.sixteen"); }
        require(false, "No stakingpools are available");
    }
    function dequeueStakingPool(string memory _queueId) private returns (address) {
        // Dequeue
        IAddressQueueStorage addressQueueStorage = IAddressQueueStorage(getContractAddress("addressQueueStorage"));
        address stakingPool = addressQueueStorage.dequeueItem(keccak256(abi.encodePacked(_queueId)));
        // Emit dequeued event
        emit StakingPoolDequeued(stakingPool, keccak256(abi.encodePacked(_queueId)), now);
        // Return
        return stakingPool;
    }

    // Remove a staking pool from a queue
    // Only accepts calls from registered stakingpools
    function removeStakingPool() override external onlyLatestContract("stafiStakingPoolQueue", address(this)) onlyRegisteredStakingPool(msg.sender) {
        // Initialize staking pool & get properties
        IStafiStakingPool stakingPool = IStafiStakingPool(msg.sender);
        DepositType depositType = stakingPool.getDepositType();
        // Remove stakingPool from queue
        if (depositType == DepositType.FOUR) { return removeStakingPool("stakingpools.available.four", msg.sender); }
        if (depositType == DepositType.EIGHT) { return removeStakingPool("stakingpools.available.eight", msg.sender); }
        if (depositType == DepositType.TWELVE) { return removeStakingPool("stakingpools.available.twelve", msg.sender); }
        if (depositType == DepositType.SIXTEEN) { return removeStakingPool("stakingpools.available.sixteen", msg.sender); }
        require(false, "Invalid deposit type");
    }
    function removeStakingPool(string memory _queueId, address _stakingPool) private {
        // Remove
        IAddressQueueStorage addressQueueStorage = IAddressQueueStorage(getContractAddress("addressQueueStorage"));
        addressQueueStorage.removeItem(keccak256(abi.encodePacked(_queueId)), _stakingPool);
        // Emit removed event
        emit StakingPoolRemoved(_stakingPool, keccak256(abi.encodePacked(_queueId)), now);
    }

}
