pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "../StafiBase.sol";
import "../interfaces/node/IStafiLightNode.sol";
import "../interfaces/node/IStafiNodeManager.sol";
import "../interfaces/deposit/IStafiUserDeposit.sol";
import "../interfaces/eth/IDepositContract.sol";
import "../interfaces/settings/IStafiNetworkSettings.sol";
import "../interfaces/storage/IPubkeySetStorage.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract StafiLightNode is StafiBase, IStafiLightNode {
    // Libs
    using SafeMath for uint256;

    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event Staked(address indexed node, bytes pubkey);
    event Deposited(address indexed node, bytes pubkey);
    event VoteWithdrawalCredentials(address node, bytes pubkey);

    uint256 public constant PUBKEY_STATUS_UNINITIAL = 0;
    uint256 public constant PUBKEY_STATUS_INITIAL = 1;
    uint256 public constant PUBKEY_STATUS_MATCH = 2;
    uint256 public constant PUBKEY_STATUS_STAKING = 3;
    uint256 public constant PUBKEY_STATUS_UNMATCH = 4;
    uint256 public constant PUBKEY_STATUS_REFOUND = 5;

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) {
        version = 1;
    }

    function EthDeposit() private view returns (IDepositContract) {
        return IDepositContract(getContractAddress("ethDeposit"));
    }

    function StafiNetworkSettings() private view returns (IStafiNetworkSettings) {
        return IStafiNetworkSettings(getContractAddress("stafiNetworkSettings"));
    }

    function PubkeySetStorage() public view returns (IPubkeySetStorage) {
        return IPubkeySetStorage(getContractAddress("pubkeySetStorage"));
    }

    // Get the number of pubkeys owned by a light node
    function getLightNodePubkeyCount(address _nodeAddress) override public view returns (uint256) {
        return PubkeySetStorage().getCount(keccak256(abi.encodePacked("lightNode.pubkeys.index", _nodeAddress)));
    }

    // Get a light node pubkey by index
    function getLightNodePubkeyAt(address _nodeAddress, uint256 _index) override public view returns (bytes memory) {
        return PubkeySetStorage().getItem(keccak256(abi.encodePacked("lightNode.pubkeys.index", _nodeAddress)), _index);
    }
    
    // Get a light node pubkey status
    function getLightNodePubkeyStatus(bytes calldata _validatorPubkey) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("lightNode.pubkey.status", _validatorPubkey)));
    }

    // Set a light node pubkey status
    function setLightNodePubkeyStatus(bytes calldata _validatorPubkey, uint256 _status) private {
        return setUint(keccak256(abi.encodePacked("lightNode.pubkey.status", _validatorPubkey)), _status);
    }

    // Deposit ETH from deposit pool
    // Only accepts calls from the StafiUserDeposit contract
    function depositEth() override external payable onlyLatestContract("stafiUserDeposit", msg.sender) {
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    function deposit(bytes[] calldata _validatorPubkeys, bytes[] calldata _validatorSignatures, bytes32[] calldata _depositDataRoots) override external onlyLatestContract("stafiLightNode", address(this)) {
        uint256 len = _validatorPubkeys.length;
        require(len == _validatorSignatures.length && len == _depositDataRoots.length);
        // Load contracts
        IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));
        stafiUserDeposit.withdrawExcessBalanceForLightNode(len.mul(4 ether));

        for (uint256 i = 0; i < len; i++) {
            _deposit(_validatorPubkeys[i], _validatorSignatures[i], _depositDataRoots[i]);
        }
    }

    function _deposit(bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot) private {
        setAndCheckNodePubkeyInDeposit(_validatorPubkey);
        // Send staking deposit to casper
        EthDeposit().deposit{value: 4 ether}(_validatorPubkey, StafiNetworkSettings().getWithdrawalCredentials(), _validatorSignature, _depositDataRoot);

        emit Deposited(msg.sender, _validatorPubkey);
    }

    function stake(bytes[] calldata _validatorPubkeys, bytes[] calldata _validatorSignatures, bytes32[] calldata _depositDataRoots) override external onlyLatestContract("stafiLightNode", address(this)) {
        require(_validatorPubkeys.length == _validatorSignatures.length && _validatorPubkeys.length == _depositDataRoots.length);
        // Load contracts
        IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));
        stafiUserDeposit.withdrawExcessBalanceForLightNode(_validatorPubkeys.length.mul(28 ether));

        for (uint256 i = 0; i < _validatorPubkeys.length; i++) {
            _stake(_validatorPubkeys[i], _validatorSignatures[i], _depositDataRoots[i]);
        }
    }

    function _stake(bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot) private {
        setAndCheckNodePubkeyInStake(_validatorPubkey);
        // Send staking deposit to casper
        EthDeposit().deposit{value: 28 ether}(_validatorPubkey, StafiNetworkSettings().getWithdrawalCredentials(), _validatorSignature, _depositDataRoot);

        emit Staked(msg.sender, _validatorPubkey);
    }

    // Set and check a node's validator pubkey
    function setAndCheckNodePubkeyInDeposit(bytes calldata _pubkey) private {
        // check pubkey of lightNodes
        require(!getBool(keccak256(abi.encodePacked("lightNode.pubkey.exists", _pubkey))), "light Node pubkey exists");
        // set validator pubkey exists in lightNodes
        setBool(keccak256(abi.encodePacked("lightNode.pubkey.exists", _pubkey)), true);
        // check pubkey of stakingpools
        require(getAddress(keccak256(abi.encodePacked("validator.stakingpool", _pubkey))) == address(0x0), "stakingpool pubkey exists");
        // check pubkey of superNodes
        require(!getBool(keccak256(abi.encodePacked("superNode.pubkey.exists", _pubkey))), "super Node pubkey exists");


        // check status
        require(getLightNodePubkeyStatus(_pubkey) == PUBKEY_STATUS_UNINITIAL, "pubkey status unmatch");
        // set pubkey status
        setLightNodePubkeyStatus(_pubkey, PUBKEY_STATUS_INITIAL);
        // add pubkey to set
        PubkeySetStorage().addItem(keccak256(abi.encodePacked("lightNode.pubkeys.index", msg.sender)), _pubkey);
    }
    
    // Set and check a node's validator pubkey
    function setAndCheckNodePubkeyInStake(bytes calldata _pubkey) private {
        // check status
        require(getLightNodePubkeyStatus(_pubkey) == PUBKEY_STATUS_MATCH, "pubkey status unmatch");
        // set pubkey status
        setLightNodePubkeyStatus(_pubkey, PUBKEY_STATUS_STAKING);
    }

    // Only accepts calls from trusted (oracle) nodes
    function voteWithdrawCredentials(bytes calldata _pubkey, bool _match) override external onlyLatestContract("stafiLightNode", address(this)) onlyTrustedNode(msg.sender) {
        // Check & update node vote status
        require(!getBool(keccak256(abi.encodePacked("lightNode.memberVotes.", _pubkey, msg.sender))), "Member has already voted to withdrawCredentials");
        setBool(keccak256(abi.encodePacked("lightNode.memberVotes.", _pubkey, msg.sender)), true);
       
        // Increment votes count
        uint256 totalVotes = getUint(keccak256(abi.encodePacked("lightNode.totalVotes", _pubkey, _match)));
        totalVotes = totalVotes.add(1);
        setUint(keccak256(abi.encodePacked("lightNode.totalVotes", _pubkey, _match)), totalVotes);
       
        // Emit event
        emit VoteWithdrawalCredentials(msg.sender, _pubkey);
       
        // Check count and set status
        uint256 calcBase = 1 ether;
        IStafiNodeManager stafiNodeManager = IStafiNodeManager(getContractAddress("stafiNodeManager"));
        if (getLightNodePubkeyStatus(_pubkey) == PUBKEY_STATUS_INITIAL &&  calcBase.mul(totalVotes) >= stafiNodeManager.getTrustedNodeCount().mul(StafiNetworkSettings().getNodeConsensusThreshold())) {
            setLightNodePubkeyStatus(_pubkey, _match ? PUBKEY_STATUS_MATCH : PUBKEY_STATUS_UNMATCH);
        }
    }
}
