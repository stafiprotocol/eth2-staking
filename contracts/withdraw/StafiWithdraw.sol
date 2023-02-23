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
    using EnumerableSet for EnumerableSet.UintSet;
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

    struct Withdrawal {
        address _address;
        uint256 _amount;
        bool _claimed;
    }

    struct NodeInfo {
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
    uint256 public ejectedStartCyle;
    uint256 public latestBalanceUpdateCycle;
    uint256 public totalUserBalance;
    uint256 public totalWaitToClaim;
    uint256 public withdrawCycleLimit;

    EnumerableSet.AddressSet subAccounts;
    mapping(bytes32 => Proposal) public proposals;
    mapping(uint256 => Withdrawal) public withdrawalAtIndex;
    mapping(address => uint256[]) public withdrawIndexListOfUser;
    mapping(uint256 => uint256) public totalWithdrawAmountAtCycle;
    mapping(address => mapping(uint256 => uint256)) public userWithdrawAmountAtCycle;

    mapping(address => NodeInfo) public infoOfNode;
    mapping(uint256 => uint256[]) public ejectedValidatorsAtCycle;

    // ------------ events ------------
    event ProposalExecuted(bytes32 indexed proposalId);
    event NotifyValidatorExit(uint256 withdrawCycle, uint256 ejectedStartWithdrawCycle, uint256[] ejectedValidators);

    constructor() StafiBase(address(0)) {
        // By setting the threshold it is not possible to call setup anymore,
        // so we create a Safe with 0 owners and threshold 1.
        // This is an unusable Safe, perfect for the singleton
        threshold = 1;
    }

    function initialize(
        address[] memory _initialSubAccounts,
        uint256 _initialThreshold,
        address _stafiStorageAddress,
        uint256 _withdrawCycleLimit
    ) external {
        require(_initialSubAccounts.length >= _initialThreshold && _initialThreshold > 0, "invalid threshold");
        require(threshold == 0, "already initizlized");

        // init StafiBase storage
        version = 1;
        stafiStorage = IStafiStorage(_stafiStorageAddress);

        // init StafiWithdraw storage
        threshold = _initialThreshold.toUint8();
        uint256 initialSubAccountCount = _initialSubAccounts.length;
        for (uint256 i; i < initialSubAccountCount; i++) {
            subAccounts.add(_initialSubAccounts[i]);
        }
        withdrawCycleLimit = _withdrawCycleLimit;
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
        uint256 ethAmount = processWithdraw(_rEthAmount);
        require(ethAmount.add(totalWaitToClaim) <= totalUserBalance, "pool balance not enough");

        totalUserBalance = totalUserBalance.sub(ethAmount);
        withdrawalAtIndex[nextWithdrawIndex] = Withdrawal({_address: msg.sender, _amount: ethAmount, _claimed: true});
        (bool result, ) = msg.sender.call{gas: 2300, value: ethAmount}("");
        require(result, "Failed to withdraw ETH");
    }

    function userWithdraw(uint256 _rEthAmount) external override {
        uint256 ethAmount = processWithdraw(_rEthAmount);
        totalWaitToClaim = totalWaitToClaim.add(ethAmount);

        withdrawalAtIndex[nextWithdrawIndex] = Withdrawal({_address: msg.sender, _amount: ethAmount, _claimed: false});
    }

    function userClaim(uint256[] calldata _withdrawIndexList) external override {
        uint256 totalAmount;
        for (uint256 i = 0; i < _withdrawIndexList.length; i++) {
            require(_withdrawIndexList[i] <= maxClaimableWithdrawIndex, "not claimable");
            require(!withdrawalAtIndex[_withdrawIndexList[i]]._claimed, "already claimed");

            withdrawalAtIndex[_withdrawIndexList[i]]._claimed = true;
            totalAmount = totalAmount.add(withdrawalAtIndex[_withdrawIndexList[i]]._amount);
        }
        if (totalAmount > 0) {
            totalWaitToClaim = totalWaitToClaim.sub(totalAmount);
            totalUserBalance = totalUserBalance.sub(totalAmount);

            (bool result, ) = msg.sender.call{gas: 2300, value: totalAmount}("");
            require(result, "user failed to claim ETH");
        }
    }

    // ------------ node withdraw ------------
    function nodeClaim() external override {
        NodeInfo memory info = infoOfNode[msg.sender];
        uint256 totalAmount = info._totalReward.sub(info._totalClaimedReward);
        info._totalClaimedReward = info._totalReward;
        totalAmount = totalAmount.add(info._totalDeposit.sub(info._totalClaimedDeposit));
        info._totalClaimedDeposit = info._totalDeposit;

        uint256 slashAmount = info._totalSlash.sub(info._totalCoveredSlash);
        if (totalAmount >= slashAmount) {
            totalAmount = totalAmount.sub(slashAmount);
            info._totalCoveredSlash = info._totalSlash;
        } else {
            totalAmount = 0;
            info._totalCoveredSlash = info._totalCoveredSlash.add(totalAmount);
        }

        infoOfNode[msg.sender] = info;

        if (totalAmount > 0) {
            (bool result, ) = msg.sender.call{gas: 2300, value: totalAmount}("");
            require(result, "node failed to claim ETH");
        }
    }

    // ------------ vote ------------
    function updateBalance(
        uint256 _latestDealedCycle,
        uint256 _addedUserBalance,
        uint256 _maxClaimableWithdrawIndex
    ) external onlySubAccount {
        require(_latestDealedCycle < currentWithdrawCycle(), "cycle not exist");
        require(_latestDealedCycle > latestBalanceUpdateCycle, "cycle already dealed");
        bytes32 proposalId = keccak256(
            abi.encodePacked(_latestDealedCycle, _addedUserBalance, _maxClaimableWithdrawIndex)
        );
        Proposal memory proposal = voteProposal(proposalId);

        // Finalize if Threshold has been reached
        if (proposal._yesVotesTotal >= threshold) {
            totalUserBalance = totalUserBalance.add(_addedUserBalance);

            maxClaimableWithdrawIndex = _maxClaimableWithdrawIndex;
            latestBalanceUpdateCycle = _latestDealedCycle;

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
                NodeInfo memory info = infoOfNode[_addresses[i]];

                info._latestStatisticBlock = _latestStatisticBlock;
                info._totalReward = info._totalReward.add(_rewards[i]);
                info._totalDeposit = info._totalDeposit.add(_deposits[i]);
                info._totalSlash = info._totalSlash.add(_slashs[i]);

                infoOfNode[_addresses[i]] = info;
            }

            proposal._status = ProposalStatus.Executed;
            emit ProposalExecuted(proposalId);
        }
        proposals[proposalId] = proposal;
    }

    function notifyValidatorExit(
        uint256 _withdrawCycle,
        uint256 _ejectedStartCycle,
        uint256[] calldata _validatorIndexList
    ) external override onlySubAccount {
        bytes32 proposalId = keccak256(abi.encodePacked(_withdrawCycle, _ejectedStartCycle, _validatorIndexList));
        Proposal memory proposal = voteProposal(proposalId);

        // Finalize if Threshold has been reached
        if (proposal._yesVotesTotal >= threshold) {
            ejectedValidatorsAtCycle[_withdrawCycle] = _validatorIndexList;
            ejectedStartCyle = _ejectedStartCycle;

            emit NotifyValidatorExit(_withdrawCycle, _ejectedStartCycle, _validatorIndexList);

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

    function emergencyWithdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "failed to withdraw");
    }

    // ------------ helper ------------

    function currentWithdrawCycle() public view returns (uint256) {
        return block.timestamp.sub(28800).div(86400);
    }

    // check:
    // 1 cycle limit
    // 2 user limit
    // return:
    // 1 eth withdraw amount
    function processWithdraw(uint256 _rEthAmount) public returns (uint256) {
        address rEthAddress = getContractAddress("rETHToken");
        uint256 ethAmount = IRETHToken(rEthAddress).getEthValue(_rEthAmount);
        uint256 currentCycle = currentWithdrawCycle();
        require(totalWithdrawAmountAtCycle[currentCycle].add(ethAmount) <= withdrawCycleLimit, "reach cycle limit");
        require(
            userWithdrawAmountAtCycle[msg.sender][currentCycle].add(ethAmount) <= withdrawCycleLimit.div(2),
            "reach user limit"
        );

        totalWithdrawAmountAtCycle[currentCycle] = totalWithdrawAmountAtCycle[currentCycle].add(ethAmount);
        userWithdrawAmountAtCycle[msg.sender][currentCycle] = userWithdrawAmountAtCycle[msg.sender][currentCycle].add(
            ethAmount
        );

        withdrawIndexListOfUser[msg.sender].push(nextWithdrawIndex);
        nextWithdrawIndex = nextWithdrawIndex.add(1);

        ERC20Burnable(rEthAddress).burnFrom(msg.sender, _rEthAmount);

        return ethAmount;
    }
}
