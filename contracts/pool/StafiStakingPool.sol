pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "../interfaces/storage/IStafiStorage.sol";
import "../types/DepositType.sol";
import "./StafiStakingPoolStorage.sol";

// An individual staking pool
contract StafiStakingPool is StafiStakingPoolStorage {

    // Events
    event EtherReceived(address indexed from, uint256 amount, uint256 time);
    event DelegateUpgraded(address oldDelegate, address newDelegate, uint256 time);
    event DelegateRolledBack(address oldDelegate, address newDelegate, uint256 time);

    // Only allow access from the owning node address
    modifier onlyStakingPoolOwner() {
        require(msg.sender == nodeAddress, "Only the node operator can access this method");
        _;
    }

    // Construct
    constructor(IStafiStorage _stafiStorageAddress, address _nodeAddress, DepositType _depositType) {
        // Initialise StafiStorage
        require(address(_stafiStorageAddress) != address(0x0), "Invalid storage address");
        stafiStorage = IStafiStorage(_stafiStorageAddress);
        // Set storage state to uninitialised
        storageState = StorageState.Uninitialised;
        // Set the current delegate
        address delegateAddress = getContractAddress("stafiStakingPoolDelegate");
        stafiStakingPoolDelegate = delegateAddress;
        // Check for contract existence
        require(contractExists(delegateAddress), "Delegate contract does not exist");
        // Call initialise on delegate
        (bool success, bytes memory data) = delegateAddress.delegatecall(abi.encodeWithSignature('initialise(address,uint8)', _nodeAddress, uint8(_depositType)));
        if (!success) { revert(getRevertMessage(data)); }
    }

    // Receive an ETH deposit
    receive() external payable {
        // Emit ether received event
        emit EtherReceived(msg.sender, msg.value, block.timestamp);
    }
   
    // Delegate all other calls to stafiStakingPoolDelegate contract
    fallback(bytes calldata _input) external payable returns (bytes memory) {
        // If useLatestDelegate is set, use the latest delegate contract
        address delegateContract = useLatestDelegate ? getContractAddress("stafiStakingPoolDelegate") : stafiStakingPoolDelegate;
        // Check for contract existence
        require(contractExists(delegateContract), "Delegate contract does not exist");
        // Execute delegatecall
        (bool success, bytes memory data) = delegateContract.delegatecall(_input);
        if (!success) { revert(getRevertMessage(data)); }
        return data;
    }


    // Upgrade this stafiStakingPool to the latest network delegate contract
    function delegateUpgrade() external onlyStakingPoolOwner {
        // Set previous address
        stafiStakingPoolDelegatePrev = stafiStakingPoolDelegate;
        // Set new delegate
        stafiStakingPoolDelegate = getContractAddress("stafiStakingPoolDelegate");
        // Verify
        require(stafiStakingPoolDelegate != stafiStakingPoolDelegatePrev, "New delegate is the same as the existing one");
        // Log event
        emit DelegateUpgraded(stafiStakingPoolDelegatePrev, stafiStakingPoolDelegate, block.timestamp);
    }

    // Rollback to previous delegate contract
    function delegateRollback() external onlyStakingPoolOwner {
        // Make sure they have upgraded before
        require(stafiStakingPoolDelegatePrev != address(0x0), "Previous delegate contract is not set");
        // Store original
        address originalDelegate = stafiStakingPoolDelegate;
        // Update delegate to previous and zero out previous
        stafiStakingPoolDelegate = stafiStakingPoolDelegatePrev;
        stafiStakingPoolDelegatePrev = address(0x0);
        // Log event
        emit DelegateRolledBack(originalDelegate, stafiStakingPoolDelegate, block.timestamp);
    }

    // If set to true, will automatically use the latest delegate contract
    function setUseLatestDelegate(bool _setting) external onlyStakingPoolOwner {
        useLatestDelegate = _setting;
    }

    // Getter for useLatestDelegate setting
    function getUseLatestDelegate() external view returns (bool) {
        return useLatestDelegate;
    }

    // Returns the address of the stakingpool's stored delegate
    function getDelegate() external view returns (address) {
        return stafiStakingPoolDelegate;
    }

    // Returns the address of the stakingPool's previous delegate (or address(0) if not set)
    function getPreviousDelegate() external view returns (address) {
        return stafiStakingPoolDelegatePrev;
    }

    // Returns the delegate which will be used when calling this stakingPool taking into account useLatestDelegate setting
    function getEffectiveDelegate() external view returns (address) {
        return useLatestDelegate ? getContractAddress("stafiStakingPoolDelegate") : stafiStakingPoolDelegate;
    }

    // Get the address of a network contract
    function getContractAddress(string memory _contractName) private view returns (address) {
        return stafiStorage.getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
    }

    // Returns true if contract exists at _contractAddress (if called during that contract's construction it will return a false negative)
    function contractExists(address _contractAddress) private view returns (bool) {
        uint32 codeSize;
        assembly {
            codeSize := extcodesize(_contractAddress)
        }
        return codeSize > 0;
    }
    
    // Get a revert message from delegatecall return data
    function getRevertMessage(bytes memory _returnData) private pure returns (string memory) {
        if (_returnData.length < 68) { return "Transaction reverted silently"; }
        assembly {
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
    }
    
}
