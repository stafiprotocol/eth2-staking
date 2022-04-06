pragma solidity 0.6.12;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiNodeDeposit {
    function deposit(bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot) external payable;
}
