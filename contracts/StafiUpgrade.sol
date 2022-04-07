pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "./StafiBase.sol";
import "./interfaces/IStafiUpgrade.sol";

// Handles contract upgrades
contract StafiUpgrade is StafiBase, IStafiUpgrade {

    // Events
    event ContractUpgraded(bytes32 indexed name, address indexed oldAddress, address indexed newAddress, uint256 time);
    event ContractAdded(bytes32 indexed name, address indexed newAddress, uint256 time);

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) {
        version = 1;
    }

    // Upgrade contract
    function upgradeContract(string memory _name, address _contractAddress) override external onlyLatestContract("stafiUpgrade", address(this)) onlySuperUser {
        // Check contract being upgraded
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        require(nameHash != keccak256(abi.encodePacked("stafiEther")), "Cannot upgrade the stafi ether contract");
        require(nameHash != keccak256(abi.encodePacked("rETHToken")), "Cannot upgrade token contracts");
        require(nameHash != keccak256(abi.encodePacked("ethDeposit")), "Cannot upgrade the eth deposit contract");
        // Get old contract address & check contract exists
        address oldContractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _name)));
        require(oldContractAddress != address(0x0), "Contract does not exist");
        // Check new contract address
        require(_contractAddress != address(0x0), "Invalid contract address");
        require(_contractAddress != oldContractAddress, "The contract address cannot be set to its current address");
        // Register new contract
        setBool(keccak256(abi.encodePacked("contract.exists", _contractAddress)), true);
        setString(keccak256(abi.encodePacked("contract.name", _contractAddress)), _name);
        setAddress(keccak256(abi.encodePacked("contract.address", _name)), _contractAddress);
        // Deregister old contract
        deleteString(keccak256(abi.encodePacked("contract.name", oldContractAddress)));
        deleteBool(keccak256(abi.encodePacked("contract.exists", oldContractAddress)));
        // Emit contract upgraded event
        emit ContractUpgraded(nameHash, oldContractAddress, _contractAddress, block.timestamp);
    }

    // Add a new network contract
    function addContract(string memory _name, address _contractAddress) override external onlyLatestContract("stafiUpgrade", address(this)) onlySuperUser {
        // Check contract name
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        require(nameHash != keccak256(abi.encodePacked("")), "Invalid contract name");
        require(getAddress(keccak256(abi.encodePacked("contract.address", _name))) == address(0x0), "Contract name is already in use");
        // Check contract address
        require(_contractAddress != address(0x0), "Invalid contract address");
        require(!getBool(keccak256(abi.encodePacked("contract.exists", _contractAddress))), "Contract address is already in use");
        // Register contract
        setBool(keccak256(abi.encodePacked("contract.exists", _contractAddress)), true);
        setString(keccak256(abi.encodePacked("contract.name", _contractAddress)), _name);
        setAddress(keccak256(abi.encodePacked("contract.address", _name)), _contractAddress);
        // Emit contract added event
        emit ContractAdded(nameHash, _contractAddress, block.timestamp);
    }

    // Init stafi storage contract
    function initStorage(bool _value) external onlySuperUser {
        setBool(keccak256(abi.encodePacked("contract.storage.initialised")), _value);
    }

    // Init stafi upgrade contract
    function initThisContract() external onlySuperUser {
        addStafiUpgradeContract(address(this));
    }

    // Upgrade stafi upgrade contract
    function upgradeThisContract(address _contractAddress) external onlySuperUser {
        addStafiUpgradeContract(_contractAddress);
    }

    // Add stafi upgrade contract
    function addStafiUpgradeContract(address _contractAddress) private {
        string memory name = "stafiUpgrade";
        bytes32 nameHash = keccak256(abi.encodePacked(name));
        address oldContractAddress = getAddress(keccak256(abi.encodePacked("contract.address", name)));
        
        setBool(keccak256(abi.encodePacked("contract.exists", _contractAddress)), true);
        setString(keccak256(abi.encodePacked("contract.name", _contractAddress)), name);
        setAddress(keccak256(abi.encodePacked("contract.address", name)), _contractAddress);
        
        if (oldContractAddress != address(0x0)) {
            deleteBool(keccak256(abi.encodePacked("contract.exists", oldContractAddress)));
            deleteString(keccak256(abi.encodePacked("contract.name", oldContractAddress)));
        }
        // Emit contract added event
        emit ContractAdded(nameHash, _contractAddress, block.timestamp);
    }

}
