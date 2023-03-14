// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.7.6;

import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

contract VerifyProof {
    function verify(
        uint256 _index,
        address _account,
        uint256 _totalRewardAmount,
        uint256 _totalExitDepositAmount,
        bytes32[] calldata _merkleProof,
        bytes32 root
    ) external pure {
        bytes32 node = keccak256(abi.encodePacked(_index, _account, _totalRewardAmount, _totalExitDepositAmount));
        require(MerkleProof.verify(_merkleProof, root, node), "invalid proof");
    }

    function encodePacked(
        uint256 _index,
        address _account,
        uint256 _totalRewardAmount,
        uint256 _totalExitDepositAmount
    ) public pure returns (bytes memory result) {
        result = abi.encodePacked(_index, _account, _totalRewardAmount, _totalExitDepositAmount);
    }

    function keccak256EncodePacked(
        uint256 _index,
        address _account,
        uint256 _totalRewardAmount,
        uint256 _totalExitDepositAmount
    ) public pure returns (bytes32 result) {
        return keccak256(abi.encodePacked(_index, _account, _totalRewardAmount, _totalExitDepositAmount));
    }
}
