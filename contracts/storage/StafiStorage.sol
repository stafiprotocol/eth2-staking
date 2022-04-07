pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "../interfaces/storage/IStafiStorage.sol";

contract StafiStorage is IStafiStorage {

    // Storage types
    mapping(bytes32 => uint256)    private uIntStorage;
    mapping(bytes32 => string)     private stringStorage;
    mapping(bytes32 => address)    private addressStorage;
    mapping(bytes32 => bytes)      private bytesStorage;
    mapping(bytes32 => bool)       private boolStorage;
    mapping(bytes32 => int256)     private intStorage;
    mapping(bytes32 => bytes32)    private bytes32Storage;


    /// @dev Only allow access from the latest version of a contract in the network after deployment
    modifier onlyLatestNetworkContract() {
        // The owner and other contracts are only allowed to set the storage upon deployment to register the initial contracts/settings, afterwards their direct access is disabled
        if (boolStorage[keccak256(abi.encodePacked("contract.storage.initialised"))] == true) {
            // Make sure the access is permitted to only contracts in our Dapp
            require(boolStorage[keccak256(abi.encodePacked("contract.exists", msg.sender))], "Invalid or outdated network contract");
        }
        _;
    }


    /// @dev Construct
    constructor() {
        // Set the main owner upon deployment
        boolStorage[keccak256(abi.encodePacked("access.role", "owner", msg.sender))] = true;
    }


    /// @param _key The key for the record
    function getAddress(bytes32 _key) override external view returns (address) {
        return addressStorage[_key];
    }

    /// @param _key The key for the record
    function getUint(bytes32 _key) override external view returns (uint256) {
        return uIntStorage[_key];
    }

    /// @param _key The key for the record
    function getString(bytes32 _key) override external view returns (string memory) {
        return stringStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes(bytes32 _key) override external view returns (bytes memory) {
        return bytesStorage[_key];
    }

    /// @param _key The key for the record
    function getBool(bytes32 _key) override external view returns (bool) {
        return boolStorage[_key];
    }

    /// @param _key The key for the record
    function getInt(bytes32 _key) override external view returns (int256) {
        return intStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes32(bytes32 _key) override external view returns (bytes32) {
        return bytes32Storage[_key];
    }


    /// @param _key The key for the record
    function setAddress(bytes32 _key, address _value) onlyLatestNetworkContract override external {
        addressStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setUint(bytes32 _key, uint256 _value) onlyLatestNetworkContract override external {
        uIntStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setString(bytes32 _key, string calldata _value) onlyLatestNetworkContract override external {
        stringStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes(bytes32 _key, bytes calldata _value) onlyLatestNetworkContract override external {
        bytesStorage[_key] = _value;
    }
    
    /// @param _key The key for the record
    function setBool(bytes32 _key, bool _value) onlyLatestNetworkContract override external {
        boolStorage[_key] = _value;
    }
    
    /// @param _key The key for the record
    function setInt(bytes32 _key, int256 _value) onlyLatestNetworkContract override external {
        intStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes32(bytes32 _key, bytes32 _value) onlyLatestNetworkContract override external {
        bytes32Storage[_key] = _value;
    }


    /// @param _key The key for the record
    function deleteAddress(bytes32 _key) onlyLatestNetworkContract override external {
        delete addressStorage[_key];
    }

    /// @param _key The key for the record
    function deleteUint(bytes32 _key) onlyLatestNetworkContract override external {
        delete uIntStorage[_key];
    }

    /// @param _key The key for the record
    function deleteString(bytes32 _key) onlyLatestNetworkContract override external {
        delete stringStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBytes(bytes32 _key) onlyLatestNetworkContract override external {
        delete bytesStorage[_key];
    }
    
    /// @param _key The key for the record
    function deleteBool(bytes32 _key) onlyLatestNetworkContract override external {
        delete boolStorage[_key];
    }
    
    /// @param _key The key for the record
    function deleteInt(bytes32 _key) onlyLatestNetworkContract override external {
        delete intStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBytes32(bytes32 _key) onlyLatestNetworkContract override external {
        delete bytes32Storage[_key];
    }


}
