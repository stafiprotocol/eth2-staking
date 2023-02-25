pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../StafiBase.sol";
import "../interfaces/IStafiEther.sol";
import "../interfaces/deposit/IStafiUserDeposit.sol";
import "../interfaces/settings/IStafiNetworkSettings.sol";
import "../interfaces/reward/IStafiFeePool.sol";
import "../interfaces/reward/IStafiSuperNodeFeePool.sol";
import "../interfaces/reward/IStafiDistributor.sol";
import "../interfaces/IStafiEtherWithdrawer.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

// Handles network validator priority fees
contract StafiDistributor is StafiBase, IStafiEtherWithdrawer, IStafiDistributor {
    // Libs
    using SafeMath for uint256;

    event Claimed(uint256 index, address account, uint256 claimedAmount, uint256 totalAmount);

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) {
        version = 1;
    }

    // Node deposits currently amount
    function getCurrentNodeDepositAmount() public view returns (uint256) {
        return getUint("settings.node.deposit.amount");
    }

    receive() external payable {}

    // Receive a ether withdrawal
    // Only accepts calls from the StafiEther contract
    function receiveEtherWithdrawal()
        external
        payable
        override
        onlyLatestContract("stafiDistributor", address(this))
        onlyLatestContract("stafiEther", msg.sender)
    {}

    function distributeFee(uint256 amount) external onlyLatestContract("stafiDistributor", address(this)) {
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

    function distributeSuperNodeFee(uint256 amount) external onlyLatestContract("stafiDistributor", address(this)) {
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

    // distribute for node and platform, accept calls from stafiWithdraw
    function distributeWithdrawals() external payable override onlyLatestContract("stafiDistributor", address(this)) {
        IStafiEther stafiEther = IStafiEther(getContractAddress("stafiEther"));
        stafiEther.depositEther{value: msg.value}();
    }

    // ----- node claim --------------
    function setMerkleRoot(bytes32 _merkleRoot) public onlyTrustedNode(msg.sender) {
        setBytes32(keccak256(abi.encodePacked("stafiDistributor.merkleRoot")), _merkleRoot);
    }

    function claim(
        uint256 _index,
        address _account,
        uint256 _totalAmount,
        bytes32[] calldata _merkleProof
    ) external onlyLatestContract("stafiDistributor", address(this)) {
        uint256 totalClaimed = getUint(keccak256(abi.encodePacked("stafiDistributor.user.totalClaimed", _account)));
        require(_totalAmount > totalClaimed, "claimable amount zero");
        bytes32 merkleRoot = getBytes32(keccak256(abi.encodePacked("rewards.claimed.merkleRoot")));

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(_index, _account, _totalAmount));
        require(MerkleProof.verify(_merkleProof, merkleRoot, node), "invalid proof");

        // Mark it claimed and send the token.
        setUint(keccak256(abi.encodePacked("stafiDistributor.user.totalClaimed", _account)), _totalAmount);

        IStafiEther stafiEther = IStafiEther(getContractAddress("stafiEther"));
        uint256 willClaimAmount = _totalAmount.sub(totalClaimed);
        stafiEther.withdrawEther(willClaimAmount);
        (bool success, ) = _account.call{value: willClaimAmount}("");
        require(success, "failed to claim ETH");

        emit Claimed(_index, _account, willClaimAmount, _totalAmount);
    }
}
