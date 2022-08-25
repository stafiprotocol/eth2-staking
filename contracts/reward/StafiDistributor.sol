pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../StafiBase.sol";
import "../interfaces/IStafiEther.sol";
import "../interfaces/deposit/IStafiUserDeposit.sol";
import "../interfaces/settings/IStafiNetworkSettings.sol";
import "../interfaces/reward/IStafiFeePool.sol";
import "../interfaces/reward/IStafiSuperNodeFeePool.sol";
import "../interfaces/IStafiEtherWithdrawer.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

// Handles network validator priority fees
contract StafiDistributor is StafiBase, IStafiEtherWithdrawer {

    // Libs
    using SafeMath for uint256;
    
    bytes32 public merkleRoot;
    uint256 public claimRound;
    // This is a packed array of booleans.
    mapping (uint256 => mapping (uint256 => uint256)) private claimedBitMap;
    
    // Events
    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 round, uint256 index, address account, uint256 amount);

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) {
        version = 1;
    }
    
    receive() external payable {}

    // Receive a ether withdrawal
    // Only accepts calls from the StafiEther contract
    function receiveEtherWithdrawal() override external payable onlyLatestContract("stafiDistributor", address(this)) onlyLatestContract("stafiEther", msg.sender) {}
    
    function distributeFee(uint256 amount) external payable onlyLatestContract("stafiDistributor", address(this)) {
        require(amount > 0, "zero amount");

        IStafiFeePool feePool = IStafiFeePool(getContractAddress("stafiFeePool"));
        IStafiNetworkSettings stafiNetworkSettings = IStafiNetworkSettings(getContractAddress("stafiNetworkSettings"));
        IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));
        IStafiEther stafiEther = IStafiEther(getContractAddress("stafiEther"));

        feePool.withdrawEther(address(this), amount);

        // Calculate platform commission
        uint256 calcBase = 1 ether;
        uint256 platformCommission = amount.mul(stafiNetworkSettings.getPlatformFee()).div(calcBase);
        uint256 leftFee = amount.sub(platformCommission);
        // Calculate node share of rewards
        uint256 nodeShare = leftFee.mul(getCurrentNodeDepositAmount()).div(32 ether);
        leftFee = leftFee.sub(nodeShare);
        // Calculate node commission on user share of rewards
        uint256 nodeCommission = leftFee.mul(stafiNetworkSettings.getNodeFee()).div(calcBase);
        // Update user reward amount
        uint256 usersFee = leftFee.sub(nodeCommission);
        uint256 nodeAndPlatformFee = amount.sub(usersFee);
        if (usersFee > 0) {
            stafiUserDeposit.recycleDistributorDeposit{value: usersFee}();
        }
        if (nodeAndPlatformFee > 0) {
            stafiEther.depositEther{value: nodeAndPlatformFee}();
        }
    }
    
    function distributeSuperNodeFee(uint256 amount) external payable onlyLatestContract("stafiDistributor", address(this)) {
        require(amount > 0, "zero amount");

        IStafiSuperNodeFeePool feePool = IStafiSuperNodeFeePool(getContractAddress("stafiSuperNodeFeePool"));
        IStafiNetworkSettings stafiNetworkSettings = IStafiNetworkSettings(getContractAddress("stafiNetworkSettings"));
        IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));
        IStafiEther stafiEther = IStafiEther(getContractAddress("stafiEther"));

        feePool.withdrawEther(address(this), amount);

        // Calculate platform commission
        uint256 calcBase = 1 ether;
        uint256 platformCommission = amount.mul(stafiNetworkSettings.getPlatformFee()).div(calcBase);
        uint256 leftFee = amount.sub(platformCommission);
        // Calculate node commission on user share of rewards
        uint256 nodeCommission = leftFee.mul(stafiNetworkSettings.getNodeFee()).div(calcBase);
        // Update user reward amount
        uint256 usersFee = leftFee.sub(nodeCommission);
        uint256 nodeAndPlatformFee = amount.sub(usersFee);
        if (usersFee > 0) {
            stafiUserDeposit.recycleDistributorDeposit{value: usersFee}();
        }
        if (nodeAndPlatformFee > 0) {
            stafiEther.depositEther{value: nodeAndPlatformFee}();
        }
    }


    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
        claimRound = claimRound.add(1);
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimRound][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimRound][claimedWordIndex] = claimedBitMap[claimRound][claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external {
        require(!isClaimed(index), 'has claimed');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'Invalid proof');

        // Mark it claimed and send the token.
        _setClaimed(index);
        (bool success,) = account.call{value: amount}("");
        require(success, "transfer tx failed");

        emit Claimed(claimRound, index, account, amount);
    }

    // Node deposits currently amount
    function getCurrentNodeDepositAmount() public view returns (uint256) {
        return getUint("settings.node.deposit.amount");
    }
}
