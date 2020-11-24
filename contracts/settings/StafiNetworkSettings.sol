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
            setNodeConsensusThreshold(0.51 ether); // 51%
            setSubmitBalancesEnabled(true);
            setSubmitBalancesFrequency(5760); // ~24 hours
            setNodeFee(0.1 ether); // 10%
            setPlatformFee(0.1 ether); // 10%
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

    // The frequency in blocks at which network balances should be submitted by trusted nodes
    function getSubmitBalancesFrequency() override public view returns (uint256) {
        return getUintS("settings.network.submit.balances.frequency");
    }
    function setSubmitBalancesFrequency(uint256 _value) public onlySuperUser {
        setUintS("settings.network.submit.balances.frequency", _value);
    }

    // The node commission rate as a fraction of 1 ether
    function getNodeFee() override public view returns (uint256) {
        return getUintS("settings.network.node.fee");
    }
    function setNodeFee(uint256 _value) public onlySuperUser {
        setUintS("settings.network.node.fee", _value);
    }

    // The platform commission rate as a fraction of 1 ether
    function getPlatformFee() override public view returns (uint256) {
        return getUintS("settings.network.platform.fee");
    }
    function setPlatformFee(uint256 _value) public onlySuperUser {
        setUintS("settings.network.platform.fee", _value);
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
