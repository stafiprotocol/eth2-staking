pragma solidity 0.6.12;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiNetworkBalances {
    function getBalancesBlock() external view returns (uint256);
    function getTotalETHBalance() external view returns (uint256);
    function getStakingETHBalance() external view returns (uint256);
    function getTotalRETHSupply() external view returns (uint256);
    function getETHStakingRate() external view returns (uint256);
    function submitBalances(uint256 _block, uint256 _total, uint256 _staking, uint256 _rethSupply) external;
}
