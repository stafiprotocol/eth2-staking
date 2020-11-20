pragma solidity 0.6.12;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiEtherWithdrawer {
    function receiveEtherWithdrawal() external payable;
}
