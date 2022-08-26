pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiNodeDeposit {
    function deposit(bytes[] calldata _validatorPubkeys, bytes[] calldata _validatorSignatures, bytes32[] calldata _depositDataRoots) external payable;
    function stake(address[] calldata _stakingPools, bytes[] calldata _validatorSignatures, bytes32[] calldata _depositDataRoots) external;
}
