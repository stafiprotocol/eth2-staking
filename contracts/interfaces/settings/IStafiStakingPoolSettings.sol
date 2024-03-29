pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "../../types/DepositType.sol";

interface IStafiStakingPoolSettings {
    function getLaunchBalance() external view returns (uint256);
    function getDepositNodeAmount(DepositType _depositType) external view returns (uint256);
    function getFourDepositNodeAmount() external view returns (uint256);
    function getEightDepositNodeAmount() external view returns (uint256);
    function getTwelveDepositNodeAmount() external view returns (uint256);
    function getSixteenDepositNodeAmount() external view returns (uint256);
    function getDepositUserAmount(DepositType _depositType) external view returns (uint256);
    function getLaunchTimeout() external view returns (uint256);
    function getStakingPoolRefundedEnabled(address _stakingPoolAddress) external view returns (bool);
    function getStakingPoolTrustedRefundedEnabled(address _stakingPoolAddress) external view returns (bool);
}
