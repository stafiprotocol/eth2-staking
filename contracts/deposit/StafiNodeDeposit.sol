pragma solidity 0.6.12;

// SPDX-License-Identifier: GPL-3.0-only

import "../StafiBase.sol";
import "../interfaces/deposit/IStafiNodeDeposit.sol";
import "../interfaces/deposit/IStafiUserDeposit.sol";
import "../interfaces/node/IStafiNodeManager.sol";
import "../interfaces/pool/IStafiStakingPool.sol";
import "../interfaces/pool/IStafiStakingPoolManager.sol";
import "../interfaces/settings/IStafiStakingPoolSettings.sol";
import "../types/DepositType.sol";

// Handles node deposits and staking pool creation
contract StafiNodeDeposit is StafiBase, IStafiNodeDeposit {

    // Events
    event DepositReceived(address indexed from, uint256 amount, uint256 time);

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) public {
        version = 1;
         // Initialize settings on deployment
        if (!getBoolS("settings.node.deposit.init")) {
            // Apply settings
            setDepositEnabled(true);
            setCurrentNodeDepositAmount(4 ether);
            // Settings initialized
            setBoolS("settings.node.deposit.init", true);
        }
    }

    // Accept a node deposit and create a new staking pool under the node
    function deposit() override external payable onlyLatestContract("stafiNodeDeposit", address(this)) {
        // Check node settings
        require(getDepositEnabled(), "Node deposits are currently disabled");
        require(msg.value == 0 || msg.value == getCurrentNodeDepositAmount(), "Invalid node deposit amount");
        // Load contracts
        IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));
        IStafiStakingPoolManager stafiStakingPoolManager = IStafiStakingPoolManager(getContractAddress("stafiStakingPoolManager"));
        IStafiStakingPoolSettings stafiStakingPoolSettings = IStafiStakingPoolSettings(getContractAddress("stafiStakingPoolSettings"));
        // Get deposit type by node deposit amount
        DepositType depositType = DepositType.None;
        if (msg.value == stafiStakingPoolSettings.getFourDepositNodeAmount()) { depositType = DepositType.FOUR; }
        else if (msg.value == stafiStakingPoolSettings.getEightDepositNodeAmount()) { depositType = DepositType.EIGHT; }
        else if (msg.value == stafiStakingPoolSettings.getTwelveDepositNodeAmount()) { depositType = DepositType.TWELVE; }
        else if (msg.value == stafiStakingPoolSettings.getSixteenDepositNodeAmount()) { depositType = DepositType.SIXTEEN; }

        IStafiNodeManager stafiNodeManager = IStafiNodeManager(getContractAddress("stafiNodeManager"));
        if (depositType == DepositType.None && stafiNodeManager.getNodeTrusted(msg.sender)) {
            depositType = DepositType.Empty;
        }
        // Check deposit type
        require(depositType != DepositType.None, "Invalid node deposit amount");
        // Emit deposit received event
        emit DepositReceived(msg.sender, msg.value, now);
        // Register the node
        stafiNodeManager.registerNode(msg.sender);
        // Create staking pool
        address stakingPoolAddress = stafiStakingPoolManager.createStakingPool(msg.sender, depositType);
        IStafiStakingPool stakingPool = IStafiStakingPool(stakingPoolAddress);
        // Transfer deposit to staking pool
        stakingPool.nodeDeposit{value: msg.value}();
        // Assign deposits if enabled
        stafiUserDeposit.assignDeposits();
    }

    // Node deposits currently enabled
    function getDepositEnabled() public view returns (bool) {
        return getBoolS("settings.node.deposit.enabled");
    }
    function setDepositEnabled(bool _value) public onlySuperUser {
        setBoolS("settings.node.deposit.enabled", _value);
    }

    // Node deposits currently amount
    function getCurrentNodeDepositAmount() public view returns (uint256) {
        return getUint("settings.node.deposit.amount");
    }
    function setCurrentNodeDepositAmount(uint256 _value) public onlySuperUser {
        IStafiStakingPoolSettings stafiStakingPoolSettings = IStafiStakingPoolSettings(getContractAddress("stafiStakingPoolSettings"));
        require(_value == stafiStakingPoolSettings.getFourDepositNodeAmount()
            || _value == stafiStakingPoolSettings.getEightDepositNodeAmount()
            || _value == stafiStakingPoolSettings.getTwelveDepositNodeAmount()
            || _value == stafiStakingPoolSettings.getSixteenDepositNodeAmount()
            , "Invalid node deposit amount");
        setUint("settings.node.deposit.amount", _value);
    }

}
