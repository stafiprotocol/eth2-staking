pragma solidity 0.7.6;
// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "../StafiBase.sol";
import "../interfaces/withdraw/IStafiWithdraw.sol";
import "../interfaces/storage/IStafiStorage.sol";
import "../interfaces/IStafiEtherWithdrawer.sol";
import "../interfaces/token/IRETHToken.sol";

contract StafiWithdraw is StafiBase, IStafiWithdraw, IStafiEtherWithdrawer {
    using SafeCast for *;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    enum ProposalStatus {
        Inactive,
        Active,
        Executed
    }

    struct Proposal {
        ProposalStatus _status;
        uint16 _yesVotes; // bitmap, 16 maximum votes
        uint8 _yesVotesTotal;
    }

    struct UserWithdrawal {
        uint256 _amount;
        bool _claimed;
    }

    struct NodeWithdrawal {
        uint256 _latestStatisticBlock;
        uint256 _totalReward;
        uint256 _totalClaimedReward;
        uint256 _totalDeposit; // total deposit amount of exited validators
        uint256 _totalClaimedDeposit;
        uint256 _totalSlash;
        uint256 _totalCoveredSlash;
    }

    uint8 public threshold;
    uint256 public nextWithdrawIndex;
    uint256 public maxClaimableWithdrawIndex;
    uint256 public totalBalance;

    EnumerableSet.AddressSet subAccounts;
    mapping(bytes32 => Proposal) public proposals;
    mapping(uint256 => UserWithdrawal) public userWithdrawals;
    mapping(address => NodeWithdrawal) public nodeWithdrawals;

    // ------------ events ------------
    event ProposalExecuted(bytes32 indexed proposalId);
    event NotifyValidatorExit(uint256 validatorIndex);

    constructor() StafiBase(address(0)) {
        threshold = 1;
    }

    function initialize(
        address[] memory _initialSubAccounts,
        uint256 _initialThreshold,
        address _stafiStorageAddress
    ) external {
        require(_initialSubAccounts.length >= _initialThreshold && _initialThreshold > 0, "invalid threshold");
        require(threshold == 0, "already initizlized");

        threshold = _initialThreshold.toUint8();
        uint256 initialSubAccountCount = _initialSubAccounts.length;
        for (uint256 i; i < initialSubAccountCount; i++) {
            subAccounts.add(_initialSubAccounts[i]);
        }

        version = 1;
        stafiStorage = IStafiStorage(_stafiStorageAddress);
    }

    modifier onlySubAccount() {
        require(subAccounts.contains(msg.sender));
        _;
    }

    // Receive eth
    receive() external payable {}

    // Receive a ether withdrawal, only accepts calls from the StafiEther contract
    function receiveEtherWithdrawal()
        external
        payable
        override
        onlyLatestContract("stafiDistributor", address(this))
        onlyLatestContract("stafiEther", msg.sender)
    {}

    // ------------ user withdraw ------------
    function userWithdrawInstantly(uint256 _rEthAmount) external override {
        address rEthAddress = getContractAddress("rETHToken");
        uint256 ethAmount = IRETHToken(rEthAddress).getEthValue(_rEthAmount);

        ERC20Burnable(rEthAddress).burnFrom(msg.sender, _rEthAmount);

        userWithdrawals[nextWithdrawIndex] = UserWithdrawal({_amount: ethAmount, _claimed: true});

        (bool result, ) = msg.sender.call{gas: 2300, value: ethAmount}("");
        require(result, "Failed to withdraw ETH");

        maxClaimableWithdrawIndex = nextWithdrawIndex;
        nextWithdrawIndex = nextWithdrawIndex.add(1);
    }

    function userWithdraw(uint256 _rEthAmount) external override {
        address rEthAddress = getContractAddress("rETHToken");
        uint256 ethAmount = IRETHToken(rEthAddress).getEthValue(_rEthAmount);

        ERC20Burnable(rEthAddress).burnFrom(msg.sender, _rEthAmount);

        userWithdrawals[nextWithdrawIndex] = UserWithdrawal({_amount: ethAmount, _claimed: false});
        nextWithdrawIndex = nextWithdrawIndex.add(1);
    }

    function userClaim(uint256[] calldata _withdrawIndexList) external override {
        uint256 totalAmount;
        for (uint256 i = 0; i < _withdrawIndexList.length; i++) {
            require(_withdrawIndexList[i] <= maxClaimableWithdrawIndex, "not claimable");
            require(!userWithdrawals[_withdrawIndexList[i]]._claimed, "already claimed");

            userWithdrawals[_withdrawIndexList[i]]._claimed = true;
            totalAmount = totalAmount.add(userWithdrawals[_withdrawIndexList[i]]._amount);
        }

        if (totalAmount > 0) {
            (bool result, ) = msg.sender.call{gas: 2300, value: totalAmount}("");
            require(result, "user failed to claim ETH");
        }
    }

    // ------------ node withdraw ------------

    function nodeClaim() external override {
        NodeWithdrawal memory withdrawal = nodeWithdrawals[msg.sender];
        uint256 totalAmount = withdrawal._totalReward.sub(withdrawal._totalClaimedReward);
        withdrawal._totalClaimedReward = withdrawal._totalReward;
        totalAmount = totalAmount.add(withdrawal._totalDeposit.sub(withdrawal._totalClaimedDeposit));
        withdrawal._totalClaimedDeposit = withdrawal._totalDeposit;

        uint256 slashAmount = withdrawal._totalSlash.sub(withdrawal._totalCoveredSlash);
        if (totalAmount >= slashAmount) {
            totalAmount = totalAmount.sub(slashAmount);
            withdrawal._totalCoveredSlash = withdrawal._totalSlash;
        } else {
            totalAmount = 0;
            withdrawal._totalCoveredSlash = withdrawal._totalCoveredSlash.add(totalAmount);
        }

        nodeWithdrawals[msg.sender] = withdrawal;

        if (totalAmount > 0) {
            (bool result, ) = msg.sender.call{gas: 2300, value: totalAmount}("");
            require(result, "node failed to claim ETH");
        }
    }

    // ------------ vote ------------
    function updateBalance(
        uint256 _latestStatisticBlock,
        uint256 _totalBalance,
        uint256 _maxClaimableWithdrawIndex
    ) external onlySubAccount {
        bytes32 proposalId = keccak256(
            abi.encodePacked(_latestStatisticBlock, _totalBalance, _maxClaimableWithdrawIndex)
        );
        Proposal memory proposal = voteProposal(proposalId);

        // Finalize if Threshold has been reached
        if (proposal._yesVotesTotal >= threshold) {
            totalBalance = _totalBalance;
            maxClaimableWithdrawIndex = _maxClaimableWithdrawIndex;

            proposal._status = ProposalStatus.Executed;
            emit ProposalExecuted(proposalId);
        }
        proposals[proposalId] = proposal;
    }

    function updateNodeReward(
        uint256 _latestStatisticBlock,
        address[] calldata _addresses,
        uint256[] calldata _rewards,
        uint256[] calldata _deposits,
        uint256[] calldata _slashs
    ) external onlySubAccount {
        bytes32 proposalId = keccak256(
            abi.encodePacked(_latestStatisticBlock, _addresses, _rewards, _deposits, _slashs)
        );
        Proposal memory proposal = voteProposal(proposalId);

        // Finalize if Threshold has been reached
        if (proposal._yesVotesTotal >= threshold) {
            for (uint256 i = 0; i < _addresses.length; i++) {
                NodeWithdrawal memory withdrawal = nodeWithdrawals[_addresses[i]];

                withdrawal._latestStatisticBlock = _latestStatisticBlock;
                withdrawal._totalReward = withdrawal._totalReward.add(_rewards[i]);
                withdrawal._totalDeposit = withdrawal._totalDeposit.add(_deposits[i]);
                withdrawal._totalSlash = withdrawal._totalSlash.add(_slashs[i]);

                nodeWithdrawals[_addresses[i]] = withdrawal;
            }

            proposal._status = ProposalStatus.Executed;
            emit ProposalExecuted(proposalId);
        }
        proposals[proposalId] = proposal;
    }

    function notifyValidatorExit(uint256 _withdrawCycle, uint256 _validatorIndex) external override onlySubAccount {
        bytes32 proposalId = keccak256(abi.encodePacked(_withdrawCycle, _validatorIndex));
        Proposal memory proposal = voteProposal(proposalId);

        // Finalize if Threshold has been reached
        if (proposal._yesVotesTotal >= threshold) {
            emit NotifyValidatorExit(_validatorIndex);

            proposal._status = ProposalStatus.Executed;
            emit ProposalExecuted(proposalId);
        }
        proposals[proposalId] = proposal;
    }

    // ------------ proposal ------------
    function addSubAccount(address _subAccount) public onlyOwner {
        subAccounts.add(_subAccount);
    }

    function removeSubAccount(address _subAccount) public onlyOwner {
        subAccounts.remove(_subAccount);
    }

    function changeThreshold(uint256 _newThreshold) external onlyOwner {
        require(subAccounts.length() >= _newThreshold && _newThreshold > 0, "invalid threshold");
        threshold = _newThreshold.toUint8();
    }

    function getSubAccountIndex(address _subAccount) public view returns (uint256) {
        return subAccounts._inner._indexes[bytes32(uint256(_subAccount))];
    }

    function subAccountBit(address _subAccount) private view returns (uint256) {
        return uint256(1) << getSubAccountIndex(_subAccount).sub(1);
    }

    function _hasVoted(Proposal memory _proposal, address _subAccount) private view returns (bool) {
        return (subAccountBit(_subAccount) & uint256(_proposal._yesVotes)) > 0;
    }

    function hasVoted(bytes32 _proposalId, address _subAccount) public view returns (bool) {
        Proposal memory proposal = proposals[_proposalId];
        return _hasVoted(proposal, _subAccount);
    }

    function voteProposal(bytes32 _proposalId) private view returns (Proposal memory) {
        Proposal memory proposal = proposals[_proposalId];

        require(uint256(proposal._status) <= 1, "proposal already executed");
        require(!_hasVoted(proposal, msg.sender), "already voted");

        if (proposal._status == ProposalStatus.Inactive) {
            proposal = Proposal({_status: ProposalStatus.Active, _yesVotes: 0, _yesVotesTotal: 0});
        }
        proposal._yesVotes = (proposal._yesVotes | subAccountBit(msg.sender)).toUint16();
        proposal._yesVotesTotal++;

        return proposal;
    }
}
