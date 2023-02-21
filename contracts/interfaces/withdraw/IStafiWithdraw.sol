pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiWithdraw {
    // user
    function userWithdrawInstantly(uint256 _rEthAmount) external;

    function userWithdraw(uint256 _rEthAmount) external;

    function userClaim(uint256[] calldata _withdrawIndexList) external;

    // node
    function nodeClaim() external;

    // ejector
    function notifyValidatorExit(uint256 _withdrawCycle, uint256[] calldata _validatorIndex) external;
}
