pragma solidity 0.6.12;

// SPDX-License-Identifier: GPL-3.0-only

import "../../types/DepositType.sol";

interface IStafiStakingPoolQueue {
    function getTotalLength() external view returns (uint256);
    function getLength(DepositType _depositType) external view returns (uint256);
    function getTotalCapacity() external view returns (uint256);
    function getEffectiveCapacity() external view returns (uint256);
    function getNextCapacity() external view returns (uint256);
    function enqueueStakingPool(DepositType _depositType, address _stakingPool) external;
    function dequeueStakingPool() external returns (address);
    function removeStakingPool() external;
}
