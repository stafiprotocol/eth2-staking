pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface IAddressQueueStorage {
    function getLength(bytes32 _key) external view returns (uint);
    function getItem(bytes32 _key, uint _index) external view returns (address);
    function getIndexOf(bytes32 _key, address _value) external view returns (int);
    function enqueueItem(bytes32 _key, address _value) external;
    function dequeueItem(bytes32 _key) external returns (address);
    function removeItem(bytes32 _key, address _value) external;
}
