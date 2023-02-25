pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiWithdraw {
    // user
    function withdrawInstantly(uint256 _rEthAmount) external;

    function withdraw(uint256 _rEthAmount) external;

    function claim(uint256[] calldata _withdrawIndexList) external;

    // ejector
    function notifyValidatorExit(
        uint256 _withdrawCycle,
        uint256 _ejectedStartWithdrawCycle,
        uint256[] calldata _validatorIndex
    ) external;

    function depositEth() external payable;
}
