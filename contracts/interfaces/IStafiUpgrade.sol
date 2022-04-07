pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiUpgrade {
    function upgradeContract(string calldata _name, address _contractAddress) external;
    function addContract(string calldata _name, address _contractAddress) external;
}
