pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "../StafiBase.sol";
import "../interfaces/node/IStafiSuperNode.sol";
import "../interfaces/deposit/IStafiUserDeposit.sol";
import "../interfaces/eth/IDepositContract.sol";
import "../interfaces/settings/IStafiNetworkSettings.sol";
import "../interfaces/storage/IPubkeySetStorage.sol";

contract StafiSuperNode is StafiBase, IStafiSuperNode {

    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event Staked(address indexed node, bytes pubkey);
    // Construct
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) {
        version = 1;
    }

    function stake(bytes[] calldata _validatorPubkeys, bytes[] calldata _validatorSignatures, bytes32[] calldata _depositDataRoots) override external onlyLatestContract("stafiSuperNode", address(this)) onlySuperNode(msg.sender) {
        require(_validatorPubkeys.length == _validatorSignatures.length && _validatorPubkeys.length == _depositDataRoots.length);

        for (uint256 i = 0; i < _validatorPubkeys.length; i++) {
            _stake(_validatorPubkeys[i], _validatorSignatures[i], _depositDataRoots[i]);
        }
    }


    function _stake(bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot) private {
        setSuperNodePubkey(_validatorPubkey);
        // Load contracts
        IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));
        stafiUserDeposit.withdrawExcessBalanceForSuperNode(32 ether);
        
        // Send staking deposit to casper
        EthDeposit().deposit{value: 32 ether}(_validatorPubkey, StafiNetworkSettings().getWithdrawalCredentials(), _validatorSignature, _depositDataRoot);

        emit Staked(msg.sender, _validatorPubkey);
    }

    function EthDeposit() private view returns (IDepositContract) {
        return IDepositContract(getContractAddress("ethDeposit"));
    }

    function StafiNetworkSettings() private view returns (IStafiNetworkSettings) {
        return IStafiNetworkSettings(getContractAddress("stafiNetworkSettings"));
    }

    // Deposit ETH from deposit pool
    // Only accepts calls from the StafiUserDeposit contract
    function depositEth() override external payable onlyLatestContract("stafiUserDeposit", msg.sender) {
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    // Set a super node's validator pubkey
    function setSuperNodePubkey(bytes calldata _pubkey) private onlyLatestContract("stafiSuperNode", address(this)){
        require(!getBool(keccak256(abi.encodePacked("superNode.pubkey.exists", _pubkey))), "superNode pubkey exists");
        require(getAddress(keccak256(abi.encodePacked("validator.stakingpool", _pubkey))) == address(0x0),"stakingpool pubkey exists");
        // Set validator pubkey
        setBool(keccak256(abi.encodePacked("superNode.pubkey.exists", _pubkey)), true);

        PubkeySetStorage().addItem(keccak256(abi.encodePacked("superNode.pubkeys.index", msg.sender)), _pubkey);
    }

    function PubkeySetStorage() public view returns (IPubkeySetStorage) {
        return IPubkeySetStorage(getContractAddress("pubkeySetStorage"));
    }

    // Get the number of pubkeys owned by a super node
    function getSuperNodePubkeyCount(address _nodeAddress) override public view returns (uint256) {
        return PubkeySetStorage().getCount(keccak256(abi.encodePacked("superNode.pubkeys.index", _nodeAddress)));
    }

    // Get a super node pubkey  by index
    function getSuperNodePubkeyAt(address _nodeAddress, uint256 _index) override public view returns (bytes memory) {
        return PubkeySetStorage().getItem(keccak256(abi.encodePacked("superNode.pubkeys.index", _nodeAddress)), _index);
    }
}
