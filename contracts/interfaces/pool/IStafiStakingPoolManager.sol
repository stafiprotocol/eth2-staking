pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "../../types/DepositType.sol";

interface IStafiStakingPoolManager {
    function getStakingPoolCount() external view returns (uint256);
    function getStakingPoolAt(uint256 _index) external view returns (address);
    function getNodeStakingPoolCount(address _nodeAddress) external view returns (uint256);
    function getNodeStakingPoolAt(address _nodeAddress, uint256 _index) external view returns (address);
    function getNodeValidatingStakingPoolCount(address _nodeAddress) external view returns (uint256);
    function getNodeValidatingStakingPoolAt(address _nodeAddress, uint256 _index) external view returns (address);
    function getStakingPoolByPubkey(bytes calldata _pubkey) external view returns (address);
    function getStakingPoolExists(address _stakingPoolAddress) external view returns (bool);
    function getStakingPoolPubkey(address _stakingPoolAddress) external view returns (bytes memory);
    function getStakingPoolWithdrawalProcessed(address _stakingPoolAddress) external view returns (bool);
    function getPrelaunchStakingpools(uint256 offset, uint256 limit) external view returns (address[] memory);
    function createStakingPool(address _nodeAddress, DepositType _depositType) external returns (address);
    function destroyStakingPool() external;
    function setStakingPoolPubkey(bytes calldata _pubkey) external;
    function setStakingPoolWithdrawalProcessed(address _stakingPoolAddress, bool _processed) external;
}
