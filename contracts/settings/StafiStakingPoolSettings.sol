pragma solidity 0.6.12;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../StafiBase.sol";
import "../interfaces/settings/IStafiStakingPoolSettings.sol";
import "../types/DepositType.sol";

// Network staking pool settings
contract StafiStakingPoolSettings is StafiBase, IStafiStakingPoolSettings {

    // Libs
    using SafeMath for uint256;

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) public {
        // Set version
        version = 1;
        // Initialize settings on deployment
        if (!getBoolS("settings.stakingpool.init")) {
            // Apply settings
            setLaunchTimeout(5760); // ~24 hours
            setNodeRefundWaitingPeriod(172800); // ~30 days
            // Settings initialized
            setBoolS("settings.stakingpool.init", true);
        }
    }

    // Balance required to launch staking pool
    function getLaunchBalance() override public view returns (uint256) {
        return 32 ether;
    }

    // Required node deposit amounts
    function getDepositNodeAmount(DepositType _depositType) override public view returns (uint256) {
        if (_depositType == DepositType.FOUR) { return getFourDepositNodeAmount(); }
        if (_depositType == DepositType.EIGHT) { return getEightDepositNodeAmount(); }
        if (_depositType == DepositType.TWELVE) { return getTwelveDepositNodeAmount(); }
        if (_depositType == DepositType.SIXTEEN) { return getSixteenDepositNodeAmount(); }
        return 0;
    }
    function getFourDepositNodeAmount() override public view returns (uint256) {
        return 4 ether;
    }
    function getEightDepositNodeAmount() override public view returns (uint256) {
        return 8 ether;
    }
    function getTwelveDepositNodeAmount() override public view returns (uint256) {
        return 12 ether;
    }
    function getSixteenDepositNodeAmount() override public view returns (uint256) {
        return 16 ether;
    }

    // Required user deposit amounts
    function getDepositUserAmount(DepositType _depositType) override public view returns (uint256) {
        if (_depositType == DepositType.None) { return 0 ether; }
        return getLaunchBalance().sub(getDepositNodeAmount(_depositType));
    }

    // Timeout period in blocks for prelaunch staking pools to launch
    function getLaunchTimeout() override public view returns (uint256) {
        return getUintS("settings.stakingpool.launch.timeout");
    }
    function setLaunchTimeout(uint256 _value) public onlySuperUser {
        setUintS("settings.stakingpool.launch.timeout", _value);
    }

    // Period in blocks for staking pools to refund
    function getNodeRefundWaitingPeriod() override public view returns (uint256) {
        return getUintS("settings.stakingpool.refund.period");
    }
    function setNodeRefundWaitingPeriod(uint256 _value) public onlySuperUser {
        setUintS("settings.stakingpool.refund.period", _value);
    }
}
