pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./StafiStakingPool.sol";
import "../StafiBase.sol";
import "../interfaces/pool/IStafiStakingPool.sol";
import "../interfaces/pool/IStafiStakingPoolManager.sol";
import "../interfaces/pool/IStafiStakingPoolQueue.sol";
import "../interfaces/storage/IAddressSetStorage.sol";
import "../types/DepositType.sol";
import "../types/StakingPoolStatus.sol";

// Staking pool creation, removal and management
contract StafiStakingPoolManager is StafiBase, IStafiStakingPoolManager {
    // Libs
    using SafeMath for uint256;
    // Events
    event StakingPoolCreated(address indexed stakingPool, address indexed node, uint256 time);
    event StakingPoolDestroyed(address indexed stakingPool, address indexed node, uint256 time);

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) {
        version = 1;
    }

    function AddressSetStorage() public view returns (IAddressSetStorage) {
        return IAddressSetStorage(getContractAddress("addressSetStorage"));
    }

    // Get the number of staking pools in the network
    function getStakingPoolCount() override public view returns (uint256) {
        return AddressSetStorage().getCount(keccak256(abi.encodePacked("stakingpools.index")));
    }

    // Get a network staking pool address by index
    function getStakingPoolAt(uint256 _index) override public view returns (address) {
        return AddressSetStorage().getItem(keccak256(abi.encodePacked("stakingpools.index")), _index);
    }

    // Get the number of staking pools owned by a node
    function getNodeStakingPoolCount(address _nodeAddress) override public view returns (uint256) {
        return AddressSetStorage().getCount(keccak256(abi.encodePacked("node.stakingpools.index", _nodeAddress)));
    }

    // Get a node staking pool address by index
    function getNodeStakingPoolAt(address _nodeAddress, uint256 _index) override public view returns (address) {
        return AddressSetStorage().getItem(keccak256(abi.encodePacked("node.stakingpools.index", _nodeAddress)), _index);
    }

    // Get the number of validating staking pools owned by a node
    function getNodeValidatingStakingPoolCount(address _nodeAddress) override public view returns (uint256) {
        return AddressSetStorage().getCount(keccak256(abi.encodePacked("node.stakingpools.validating.index", _nodeAddress)));
    }

    // Get a validating node staking pool address by index
    function getNodeValidatingStakingPoolAt(address _nodeAddress, uint256 _index) override public view returns (address) {
        return AddressSetStorage().getItem(keccak256(abi.encodePacked("node.stakingpools.validating.index", _nodeAddress)), _index);
    }

    // Get a staking pool address by validator pubkey
    function getStakingPoolByPubkey(bytes memory _pubkey) override public view returns (address) {
        return getAddress(keccak256(abi.encodePacked("validator.stakingpool", _pubkey)));
    }

    // Check whether a staking pool exists
    function getStakingPoolExists(address _stakingPoolAddress) override public view returns (bool) {
        return getBool(keccak256(abi.encodePacked("stakingpool.exists", _stakingPoolAddress)));
    }

    // Get a staking pool's validator pubkey
    function getStakingPoolPubkey(address _stakingPoolAddress) override public view returns (bytes memory) {
        return getBytes(keccak256(abi.encodePacked("stakingpool.pubkey", _stakingPoolAddress)));
    }

    // Get a staking pool's withdrawal processed status
    function getStakingPoolWithdrawalProcessed(address _stakingPoolAddress) override public view returns (bool) {
        return getBool(keccak256(abi.encodePacked("stakingpool.withdrawal.processed", _stakingPoolAddress)));
    }

    // Returns an array of all stakingPools in the prelaunch state
    function getPrelaunchStakingpools(uint256 offset, uint256 limit) override external view returns (address[] memory) {
        // Precompute stakingPool key
        bytes32 stakingPoolKey = keccak256(abi.encodePacked("stakingpools.index"));
        // Iterate over the requested stakingPool range
        uint256 totalStakingPools = getStakingPoolCount();
        uint256 max = offset.add(limit);
        if (max > totalStakingPools || limit == 0) { max = totalStakingPools; }
        // Create array big enough for every staking pool
        address[] memory stakingPools = new address[](max.sub(offset));
        uint256 total = 0;
        for (uint256 i = offset; i < max; i++) {
            // Get the staking pool at index i
            IStafiStakingPool stakingPool = IStafiStakingPool(AddressSetStorage().getItem(stakingPoolKey, i));
            // Get the staking pool's status, and to array if it's in prelaunch
            if (stakingPool.getStatus() == StakingPoolStatus.Prelaunch) {
                stakingPools[total] = address(stakingPool);
                total++;
            }
        }
        // Dirty hack to cut unused elements off end of return value
        assembly {
            mstore(stakingPools, total)
        }
        return stakingPools;
    }

    // Create a staking pool
    // Only accepts calls from the StafiNodeDeposit contract
    function createStakingPool(address _nodeAddress, DepositType _depositType) override external onlyLatestContract("stafiStakingPoolManager", address(this)) onlyLatestContract("stafiNodeDeposit", msg.sender) returns (address) {
        IStafiStakingPoolQueue stafiStakingPoolQueue = IStafiStakingPoolQueue(getContractAddress("stafiStakingPoolQueue"));
        // Create staking pool contract
        address contractAddress = address(new StafiStakingPool(IStafiStorage(stafiStorage), _nodeAddress, _depositType));
        // Initialize staking pool data
        setBool(keccak256(abi.encodePacked("stakingpool.exists", contractAddress)), true);
        // Add staking pool to indexes
        AddressSetStorage().addItem(keccak256(abi.encodePacked("stakingpools.index")), contractAddress);
        AddressSetStorage().addItem(keccak256(abi.encodePacked("node.stakingpools.index", _nodeAddress)), contractAddress);
        // Emit staking pool created event
        emit StakingPoolCreated(contractAddress, _nodeAddress, block.timestamp);
        // Add staking pool to queue
        stafiStakingPoolQueue.enqueueStakingPool(_depositType, contractAddress);
        // Return created staking pool address
        return contractAddress;
    }

    // Destroy a staking pool
    // Only accepts calls from registered stakingpools
    function destroyStakingPool() override external onlyLatestContract("stafiStakingPoolManager", address(this)) onlyRegisteredStakingPool(msg.sender) {
        // Initialize staking pool & get properties
        address nodeAddress = IStafiStakingPool(msg.sender).getNodeAddress();
        // Update staking pool data
        setBool(keccak256(abi.encodePacked("stakingpool.exists", msg.sender)), false);
        // Remove staking pool from indexes
        AddressSetStorage().removeItem(keccak256(abi.encodePacked("stakingpools.index")), msg.sender);
        AddressSetStorage().removeItem(keccak256(abi.encodePacked("node.stakingpools.index", nodeAddress)), msg.sender);
        // Emit staking pool destroyed event
        emit StakingPoolDestroyed(msg.sender, nodeAddress, block.timestamp);
    }

    // Set a staking pool's validator pubkey
    // Only accepts calls from registered stakingpools
    function setStakingPoolPubkey(bytes calldata _pubkey) override external onlyLatestContract("stafiStakingPoolManager", address(this)) onlyRegisteredStakingPool(msg.sender) {
        // Initialize staking pool & get properties
        address nodeAddress = IStafiStakingPool(msg.sender).getNodeAddress();
        // Set staking pool validator pubkey & validator staking pool address
        setBytes(keccak256(abi.encodePacked("stakingpool.pubkey", msg.sender)), _pubkey);
        setAddress(keccak256(abi.encodePacked("validator.stakingpool", _pubkey)), msg.sender);
        // Add staking pool to node validating stakingpools index
        AddressSetStorage().addItem(keccak256(abi.encodePacked("node.stakingpools.validating.index", nodeAddress)), msg.sender);
    }

    // Set a staking pool's withdrawal processed status
    function setStakingPoolWithdrawalProcessed(address _stakingPoolAddress, bool _processed) override external onlyLatestContract("stafiStakingPoolManager", address(this)) onlyLatestContract("stafiNetworkWithdrawal", msg.sender) {
        setBool(keccak256(abi.encodePacked("stakingpool.withdrawal.processed", _stakingPoolAddress)), _processed);
    }

}
