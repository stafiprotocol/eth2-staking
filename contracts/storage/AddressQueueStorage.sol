pragma solidity 0.6.12;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../StafiBase.sol";
import "../interfaces/storage/IAddressQueueStorage.sol";

// Address queue storage helper
contract AddressQueueStorage is StafiBase, IAddressQueueStorage {

    // Libs
    using SafeMath for uint256;

    // Settings
    uint256 public capacity = 2 ** 255; // max uint256 / 2

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) public {
        version = 1;
    }

    // The number of items in a queue
    function getLength(bytes32 _key) override public view returns (uint256) {
        uint256 start = getUint(keccak256(abi.encodePacked(_key, ".start")));
        uint256 end = getUint(keccak256(abi.encodePacked(_key, ".end")));
        if (end < start) { end = end.add(capacity); }
        return end.sub(start);
    }

    // The item in a queue by index
    function getItem(bytes32 _key, uint256 _index) override external view returns (address) {
        uint256 index = getUint(keccak256(abi.encodePacked(_key, ".start"))).add(_index);
        if (index >= capacity) { index = index.sub(capacity); }
        return getAddress(keccak256(abi.encodePacked(_key, ".item", index)));
    }

    // The index of an item in a queue
    // Returns -1 if the value is not found
    function getIndexOf(bytes32 _key, address _value) override external view returns (int) {
        int256 index = int256(getUint(keccak256(abi.encodePacked(_key, ".index", _value)))) - 1;
        if (index != -1) {
            index -= int256(getUint(keccak256(abi.encodePacked(_key, ".start"))));
            if (index < 0) { index += int256(capacity); }
        }
        return index;
    }

    // Add an item to the end of a queue
    // Requires that the queue is not at capacity
    // Requires that the item does not exist in the queue
    function enqueueItem(bytes32 _key, address _value) override external onlyLatestContract("addressQueueStorage", address(this)) onlyLatestNetworkContract {
        require(getLength(_key) < capacity - 1, "Queue is at capacity");
        require(getUint(keccak256(abi.encodePacked(_key, ".index", _value))) == 0, "Item already exists in queue");
        uint256 index = getUint(keccak256(abi.encodePacked(_key, ".end")));
        setAddress(keccak256(abi.encodePacked(_key, ".item", index)), _value);
        setUint(keccak256(abi.encodePacked(_key, ".index", _value)), index + 1);
        index = index.add(1);
        if (index >= capacity) { index = index.sub(capacity); }
        setUint(keccak256(abi.encodePacked(_key, ".end")), index);
    }

    // Remove an item from the start of a queue and return it
    // Requires that the queue is not empty
    function dequeueItem(bytes32 _key) override external onlyLatestContract("addressQueueStorage", address(this)) onlyLatestNetworkContract returns (address) {
        require(getLength(_key) > 0, "Queue is empty");
        uint256 start = getUint(keccak256(abi.encodePacked(_key, ".start")));
        address item = getAddress(keccak256(abi.encodePacked(_key, ".item", start)));
        start = start.add(1);
        if (start >= capacity) { start = start.sub(capacity); }
        setUint(keccak256(abi.encodePacked(_key, ".index", item)), 0);
        setUint(keccak256(abi.encodePacked(_key, ".start")), start);
        return item;
    }

    // Remove an item from a queue
    // Swaps the item with the last item in the queue and truncates it; computationally cheap
    // Requires that the item exists in the queue
    function removeItem(bytes32 _key, address _value) override external onlyLatestContract("addressQueueStorage", address(this)) onlyLatestNetworkContract {
        uint256 index = getUint(keccak256(abi.encodePacked(_key, ".index", _value)));
        require(index-- > 0, "Item does not exist in queue");
        uint256 lastIndex = getUint(keccak256(abi.encodePacked(_key, ".end")));
        if (lastIndex == 0) lastIndex = capacity;
        lastIndex = lastIndex.sub(1);
        if (index != lastIndex) {
            address lastItem = getAddress(keccak256(abi.encodePacked(_key, ".item", lastIndex)));
            setAddress(keccak256(abi.encodePacked(_key, ".item", index)), lastItem);
            setUint(keccak256(abi.encodePacked(_key, ".index", lastItem)), index + 1);
        }
        setUint(keccak256(abi.encodePacked(_key, ".index", _value)), 0);
        setUint(keccak256(abi.encodePacked(_key, ".end")), lastIndex);
    }

}
