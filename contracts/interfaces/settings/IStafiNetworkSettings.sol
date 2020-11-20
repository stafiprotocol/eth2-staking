pragma solidity 0.6.12;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiNetworkSettings {
    function getNodeConsensusThreshold() external view returns (uint256);
    function getSubmitBalancesEnabled() external view returns (bool);
    function getSubmitBalancesFrequency() external view returns (uint256);
    function getTargetNodeFee() external view returns (uint256);
    function getWithdrawalCredentials() external view returns (bytes memory);
}
