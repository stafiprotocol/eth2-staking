pragma solidity 0.6.12;

// SPDX-License-Identifier: GPL-3.0-only

import "../StafiBase.sol";
import "../interfaces/node/IStafiNodeManager.sol";
import "../interfaces/storage/IAddressSetStorage.sol";

// Node registration and management
contract StafiNodeManager is StafiBase, IStafiNodeManager {

    // Events
    event NodeRegistered(address indexed node, uint256 time);
    event NodeTrustedSet(address indexed node, bool trusted, uint256 time);

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) public {
        version = 1;
        setRegistrationEnabled(true);
    }

    // Node registrations currently enabled
    function getRegistrationEnabled() public view returns (bool) {
        return getBoolS("settings.node.registration.enabled");
    }
    function setRegistrationEnabled(bool _value) public onlySuperUser {
        setBoolS("settings.node.registration.enabled", _value);
    }

    // Get the number of nodes in the network
    function getNodeCount() override public view returns (uint256) {
        IAddressSetStorage addressSetStorage = IAddressSetStorage(getContractAddress("addressSetStorage"));
        return addressSetStorage.getCount(keccak256(abi.encodePacked("nodes.index")));
    }

    // Get a node address by index
    function getNodeAt(uint256 _index) override public view returns (address) {
        IAddressSetStorage addressSetStorage = IAddressSetStorage(getContractAddress("addressSetStorage"));
        return addressSetStorage.getItem(keccak256(abi.encodePacked("nodes.index")), _index);
    }

    // Get the number of trusted nodes in the network
    function getTrustedNodeCount() override public view returns (uint256) {
        IAddressSetStorage addressSetStorage = IAddressSetStorage(getContractAddress("addressSetStorage"));
        return addressSetStorage.getCount(keccak256(abi.encodePacked("nodes.trusted.index")));
    }

    // Get a trusted node address by index
    function getTrustedNodeAt(uint256 _index) override public view returns (address) {
        IAddressSetStorage addressSetStorage = IAddressSetStorage(getContractAddress("addressSetStorage"));
        return addressSetStorage.getItem(keccak256(abi.encodePacked("nodes.trusted.index")), _index);
    }

    // Check whether a node exists
    function getNodeExists(address _nodeAddress) override public view returns (bool) {
        return getBool(keccak256(abi.encodePacked("node.exists", _nodeAddress)));
    }

    // Check whether a node is trusted
    function getNodeTrusted(address _nodeAddress) override public view returns (bool) {
        return getBool(keccak256(abi.encodePacked("node.trusted", _nodeAddress)));
    }

    // Register a new node
    function registerNode() override external onlyLatestContract("stafiNodeManager", address(this)) {
        // Load contracts
        IAddressSetStorage addressSetStorage = IAddressSetStorage(getContractAddress("addressSetStorage"));
        // Check node settings
        require(getRegistrationEnabled(), "Node registrations are currently disabled");
        // Check node is not registered
        require(!getBool(keccak256(abi.encodePacked("node.exists", msg.sender))), "The node is already registered in the network");
        // Initialise node data
        setBool(keccak256(abi.encodePacked("node.exists", msg.sender)), true);
        setBool(keccak256(abi.encodePacked("node.trusted", msg.sender)), false);
        // Add node to index
        addressSetStorage.addItem(keccak256(abi.encodePacked("nodes.index")), msg.sender);
        // Emit node registered event
        emit NodeRegistered(msg.sender, now);
    }

    // Set a node's trusted status
    // Only accepts calls from super users
    function setNodeTrusted(address _nodeAddress, bool _trusted) override external onlyLatestContract("stafiNodeManager", address(this)) onlySuperUser {
        // Check node exists
        require(getBool(keccak256(abi.encodePacked("node.exists", _nodeAddress))), "The node does not exist");
        // Check current node status
        require(getBool(keccak256(abi.encodePacked("node.trusted", _nodeAddress))) != _trusted, "The node's trusted status is already set");
        // Load contracts
        IAddressSetStorage addressSetStorage = IAddressSetStorage(getContractAddress("addressSetStorage"));
        // Set status
        setBool(keccak256(abi.encodePacked("node.trusted", _nodeAddress)), _trusted);
        // Add node to / remove node from trusted index
        if (_trusted) { addressSetStorage.addItem(keccak256(abi.encodePacked("nodes.trusted.index")), _nodeAddress); }
        else { addressSetStorage.removeItem(keccak256(abi.encodePacked("nodes.trusted.index")), _nodeAddress); }
        // Emit node trusted set event
        emit NodeTrustedSet(_nodeAddress, _trusted, now);
    }

}
