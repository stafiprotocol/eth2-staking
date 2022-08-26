pragma solidity 0.7.6;
pragma abicoder v2;
// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/math/SafeMath.sol";
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
    // Libs
    using SafeMath for uint256;
    // Events
    event DepositReceived(address indexed from, uint256 amount, uint256 time);

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) {
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

    function deposit(bytes[] calldata _validatorPubkeys, bytes[] calldata _validatorSignatures, bytes32[] calldata _depositDataRoots) override external payable onlyLatestContract("stafiNodeDeposit", address(this)) {
        require(_validatorPubkeys.length == _validatorSignatures.length && _validatorPubkeys.length == _depositDataRoots.length, "params len err");
        require(msg.value == getCurrentNodeDepositAmount().mul(_validatorPubkeys.length), "Invalid node deposit amount");

        for (uint256 i = 0; i < _validatorPubkeys.length; i++) {
            _deposit(_validatorPubkeys[i], _validatorSignatures[i], _depositDataRoots[i]);
        }
    }

    // Accept a node deposit and create a new staking pool under the node
    function _deposit(bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot) private {
        // Check node settings
        require(getDepositEnabled(), "Node deposits are currently disabled");
        uint256 depositValue = getCurrentNodeDepositAmount();
        // Load contracts
        IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));
        IStafiStakingPoolManager stafiStakingPoolManager = IStafiStakingPoolManager(getContractAddress("stafiStakingPoolManager"));
        IStafiStakingPoolSettings stafiStakingPoolSettings = IStafiStakingPoolSettings(getContractAddress("stafiStakingPoolSettings"));
        // Get deposit type by node deposit amount
        DepositType depositType = DepositType.None;
        if (depositValue == stafiStakingPoolSettings.getFourDepositNodeAmount()) { depositType = DepositType.FOUR; }
        else if (depositValue == stafiStakingPoolSettings.getEightDepositNodeAmount()) { depositType = DepositType.EIGHT; }
        else if (depositValue == stafiStakingPoolSettings.getTwelveDepositNodeAmount()) { depositType = DepositType.TWELVE; }
        else if (depositValue == stafiStakingPoolSettings.getSixteenDepositNodeAmount()) { depositType = DepositType.SIXTEEN; }

        IStafiNodeManager stafiNodeManager = IStafiNodeManager(getContractAddress("stafiNodeManager"));
        if (depositType == DepositType.None && stafiNodeManager.getNodeTrusted(msg.sender)) {
            depositType = DepositType.Empty;
        }
        // Check deposit type
        require(depositType != DepositType.None, "Invalid node deposit amount");
        // Emit deposit received event
        emit DepositReceived(msg.sender, depositValue, block.timestamp);
        // Register the node
        stafiNodeManager.registerNode(msg.sender);
        // Create staking pool
        // address stakingPoolAddress = stafiStakingPoolManager.createStakingPool(msg.sender, depositType);
        IStafiStakingPool stakingPool = IStafiStakingPool(stafiStakingPoolManager.createStakingPool(msg.sender, depositType));
        // Transfer deposit to staking pool
        stakingPool.nodeDeposit{value: depositValue}(_validatorPubkey, _validatorSignature, _depositDataRoot);
        // Assign deposits if enabled
        stafiUserDeposit.assignDeposits();
    }

    function stake(address[] calldata _stakingPools, bytes[] calldata _validatorSignatures, bytes32[] calldata _depositDataRoots) override external onlyLatestContract("stafiNodeDeposit", address(this)) {
        require(_validatorSignatures.length == _depositDataRoots.length && _stakingPools.length == _validatorSignatures.length, "params len err");

        for (uint256 i = 0; i < _validatorSignatures.length; i++) {
            IStafiStakingPool stakingPool = IStafiStakingPool(_stakingPools[i]);
            stakingPool.stake(_validatorSignatures[i], _depositDataRoots[i]);
        }
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
