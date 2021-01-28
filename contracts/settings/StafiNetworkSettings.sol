pragma solidity 0.6.12;

// SPDX-License-Identifier: GPL-3.0-only

import "../StafiBase.sol";
import "../interfaces/settings/IStafiNetworkSettings.sol";

// Network settings
contract StafiNetworkSettings is StafiBase, IStafiNetworkSettings {

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) public {
        // Set version
        version = 1;
        // Initialize settings on deployment
        if (!getBoolS("settings.network.init")) {
            // Apply settings
            setNodeConsensusThreshold(0.5 ether); // 50%
            setSubmitBalancesEnabled(true);
            setProcessWithdrawalsEnabled(true);
            setNodeFee(0.1 ether); // 10%
            setPlatformFee(0.1 ether); // 10%
            setNodeRefundRatio(0.25 ether); // 25%
            setNodeTrustedRefundRatio(0.5 ether); // 50%
            // Settings initialized
            setBoolS("settings.network.init", true);
        }
    }

    // The threshold of trusted nodes that must reach consensus on oracle data to commit it
    function getNodeConsensusThreshold() override public view returns (uint256) {
        return getUintS("settings.network.consensus.threshold");
    }
    function setNodeConsensusThreshold(uint256 _value) public onlySuperUser {
        setUintS("settings.network.consensus.threshold", _value);
    }

    // Submit balances currently enabled (trusted nodes only)
    function getSubmitBalancesEnabled() override public view returns (bool) {
        return getBoolS("settings.network.submit.balances.enabled");
    }
    function setSubmitBalancesEnabled(bool _value) public onlySuperUser {
        setBoolS("settings.network.submit.balances.enabled", _value);
    }

    // Process withdrawals currently enabled (trusted nodes only)
    function getProcessWithdrawalsEnabled() override public view returns (bool) {
        return getBoolS("settings.network.process.withdrawals.enabled");
    }
    function setProcessWithdrawalsEnabled(bool _value) public onlySuperUser {
        setBoolS("settings.network.process.withdrawals.enabled", _value);
    }

    // The node commission rate as a fraction of 1 ether
    function getNodeFee() override public view returns (uint256) {
        return getUintS("settings.network.node.fee");
    }
    function setNodeFee(uint256 _value) public onlySuperUser {
        require( _value <= 1 ether, "Invalid value");
        setUintS("settings.network.node.fee", _value);
    }

    // The platform commission rate as a fraction of 1 ether
    function getPlatformFee() override public view returns (uint256) {
        return getUintS("settings.network.platform.fee");
    }
    function setPlatformFee(uint256 _value) public onlySuperUser {
        require( _value <= 1 ether, "Invalid value");
        setUintS("settings.network.platform.fee", _value);
    }

    // The node refund commission rate as a fraction of 1 ether
    function getNodeRefundRatio() override public view returns (uint256) {
        return getUintS("settings.network.node.refund.ratio");
    }
    function setNodeRefundRatio(uint256 _value) public onlySuperUser {
        require( _value <= 1 ether, "Invalid value");
        setUintS("settings.network.node.refund.ratio", _value);
    }

    // The trusted node refund commission rate as a fraction of 1 ether
    function getNodeTrustedRefundRatio() override public view returns (uint256) {
        return getUintS("settings.network.node.trusted.refund.ratio");
    }
    function setNodeTrustedRefundRatio(uint256 _value) public onlySuperUser {
        require( _value <= 1 ether, "Invalid value");
        setUintS("settings.network.node.trusted.refund.ratio", _value);
    }

    // Get the validator withdrawal credentials
    function getWithdrawalCredentials() override public view returns (bytes memory) {
        return getBytesS("settings.network.withdrawal.credentials");
    }

    // Set the validator withdrawal credentials
    function setWithdrawalCredentials(bytes memory _value) public onlySuperUser {
        setBytesS("settings.network.withdrawal.credentials", _value);
    }

}
