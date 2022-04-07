pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiNetworkWithdrawal {
    function getBalance() external view returns (uint256);
    function withdrawStakingPool(address _stakingPoolAddress, uint256 _stakingStartBalance, uint256 _stakingEndBalance) external;
    function getStakingPoolNodeRewardAmount(uint256 _platformFee, uint256 _nodeFee, uint256 _nodeDeposit, uint256 _userDeposit, uint256 _startBalance, uint256 _endBalance) external pure returns (uint256);
    function getStakingPoolUserRewardAmount(uint256 _platformFee, uint256 _nodeFee, uint256 _nodeDeposit, uint256 _userDeposit, uint256 _startBalance, uint256 _endBalance) external pure returns (uint256);
}
