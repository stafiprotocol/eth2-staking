pragma solidity 0.7.6;
pragma abicoder v2;
// SPDX-License-Identifier: GPL-3.0-only

interface IStafiWithdraw {
    // user

    function unstake(uint256 _rEthAmount) external;

    function withdraw(uint256[] calldata _withdrawIndexList) external;

    // ejector
    function requestValidatorExit(uint256 _withdrawCycle, bytes[] calldata _validatorIndex) external payable;

    // voter
    function distributeWithdrawals(
        uint256 _dealedHeight,
        uint256 _userAmount,
        uint256 _nodeAmount,
        uint256 _platformAmount,
        uint256 _maxClaimableWithdrawIndex
    ) external;

    function reserveEthForWithdraw(uint256 _withdrawCycle) external;

    function depositEth() external payable;

    function getUnclaimedWithdrawalsOfUser(address user) external view returns (uint256[] memory);
}
