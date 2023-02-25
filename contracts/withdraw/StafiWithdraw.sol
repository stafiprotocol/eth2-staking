pragma solidity 0.7.6;
// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "../StafiBase.sol";
import "../interfaces/withdraw/IStafiWithdraw.sol";
import "../interfaces/storage/IStafiStorage.sol";
import "../interfaces/token/IRETHToken.sol";
import "../interfaces/settings/IStafiNetworkSettings.sol";
import "../interfaces/node/IStafiNodeManager.sol";
import "../interfaces/reward/IStafiDistributor.sol";
import "../interfaces/deposit/IStafiUserDeposit.sol";

// Notice:
// 1 proxy admin must be different from owner
// 2 the new storage needs to be appended to the old storage if this contract is upgraded,
contract StafiWithdraw is StafiBase, IStafiWithdraw {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Withdrawal {
        address _address;
        uint256 _amount;
        bool _claimed;
    }

    uint256 public nextWithdrawIndex;
    uint256 public maxClaimableWithdrawIndex;
    uint256 public ejectedStartCyle;
    uint256 public latestDistributeHeight;
    uint256 public totalMissingAmountForWithdraw;
    uint256 public withdrawCycleLimit;

    mapping(uint256 => Withdrawal) public withdrawalAtIndex;
    mapping(address => EnumerableSet.UintSet) internal unclaimedWithdrawalsOfUser;
    mapping(address => EnumerableSet.UintSet) internal claimedWithdrawalsOfUser;
    mapping(uint256 => uint256) public totalWithdrawAmountAtCycle;
    mapping(address => mapping(uint256 => uint256)) public userWithdrawAmountAtCycle;
    mapping(uint256 => uint256[]) public ejectedValidatorsAtCycle;

    // ------------ events ------------
    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event ProposalExecuted(bytes32 indexed proposalId);
    event NotifyValidatorExit(uint256 withdrawCycle, uint256 ejectedStartWithdrawCycle, uint256[] ejectedValidators);

    constructor() StafiBase(address(0)) {
        // By setting the version it is not possible to call setup anymore,
        // so we create a Safe with version 1.
        // This is an unusable Safe, perfect for the singleton
        version = 1;
    }

    function initialize(address _stafiStorageAddress, uint256 _withdrawCycleLimit) external {
        require(version == 0, "already initizlized");
        // init StafiBase storage
        version = 1;
        stafiStorage = IStafiStorage(_stafiStorageAddress);
        // init StafiWithdraw storage
        withdrawCycleLimit = _withdrawCycleLimit;
    }

    // Receive eth
    receive() external payable {}

    // Deposit ETH from deposit pool
    // Only accepts calls from the StafiUserDeposit contract
    function depositEth() external payable override onlyLatestContract("stafiUserDeposit", msg.sender) {
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    // ------------ user withdraw ------------
    function withdrawInstantly(
        uint256 _rEthAmount
    ) external override onlyLatestContract("stafiWithdraw", address(this)) {
        uint256 ethAmount = processWithdraw(_rEthAmount);
        IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));
        uint256 stakePoolBalance = stafiUserDeposit.getBalance();

        require(ethAmount <= stakePoolBalance, "stake pool balance not enough");
        stafiUserDeposit.withdrawExcessBalanceForWithdraw(ethAmount);

        withdrawalAtIndex[nextWithdrawIndex] = Withdrawal({_address: msg.sender, _amount: ethAmount, _claimed: true});
        claimedWithdrawalsOfUser[msg.sender].add(nextWithdrawIndex);
        nextWithdrawIndex = nextWithdrawIndex.add(1);

        (bool result, ) = msg.sender.call{gas: 2300, value: ethAmount}("");
        require(result, "Failed to withdraw ETH");
    }

    function withdraw(uint256 _rEthAmount) external override onlyLatestContract("stafiWithdraw", address(this)) {
        uint256 ethAmount = processWithdraw(_rEthAmount);
        IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));
        uint256 stakePoolBalance = stafiUserDeposit.getBalance();

        if (stakePoolBalance > 0) {
            uint256 mvAmount = ethAmount;
            if (stakePoolBalance < ethAmount) {
                mvAmount = stakePoolBalance;
                totalMissingAmountForWithdraw = totalMissingAmountForWithdraw.add(ethAmount.sub(stakePoolBalance));
            }
            stafiUserDeposit.withdrawExcessBalanceForWithdraw(mvAmount);
        } else {
            totalMissingAmountForWithdraw = totalMissingAmountForWithdraw.add(ethAmount);
        }

        withdrawalAtIndex[nextWithdrawIndex] = Withdrawal({_address: msg.sender, _amount: ethAmount, _claimed: false});
        unclaimedWithdrawalsOfUser[msg.sender].add(nextWithdrawIndex);
        nextWithdrawIndex = nextWithdrawIndex.add(1);
    }

    function claim(
        uint256[] calldata _withdrawIndexList
    ) external override onlyLatestContract("stafiWithdraw", address(this)) {
        uint256 totalAmount;
        for (uint256 i = 0; i < _withdrawIndexList.length; i++) {
            require(_withdrawIndexList[i] <= maxClaimableWithdrawIndex, "not claimable");
            require(!withdrawalAtIndex[_withdrawIndexList[i]]._claimed, "already claimed");

            withdrawalAtIndex[_withdrawIndexList[i]]._claimed = true;
            totalAmount = totalAmount.add(withdrawalAtIndex[_withdrawIndexList[i]]._amount);

            unclaimedWithdrawalsOfUser[msg.sender].remove(_withdrawIndexList[i]);
            claimedWithdrawalsOfUser[msg.sender].add(_withdrawIndexList[i]);
        }

        if (totalAmount > 0) {
            (bool result, ) = msg.sender.call{gas: 2300, value: totalAmount}("");
            require(result, "user failed to claim ETH");
        }
    }

    // ------------ voter(trust node) ------------
    function distributeWithdrawals(
        uint256 _dealedHeight,
        uint256 _userAmount,
        uint256 _nodeAmount,
        uint256 _platformAmount,
        uint256 _maxClaimableWithdrawIndex
    ) external onlyLatestContract("stafiWithdraw", address(this)) onlyTrustedNode(msg.sender) {
        require(_dealedHeight > latestDistributeHeight, "height already dealed");
        bytes32 proposalId = keccak256(
            abi.encodePacked(_dealedHeight, _userAmount, _nodeAmount, _platformAmount, _maxClaimableWithdrawIndex)
        );
        bool needExe = voteProposal(proposalId);

        // Finalize if Threshold has been reached
        if (needExe) {
            maxClaimableWithdrawIndex = _maxClaimableWithdrawIndex;
            latestDistributeHeight = _dealedHeight;

            uint256 mvAmount = _userAmount;
            if (totalMissingAmountForWithdraw < _userAmount) {
                mvAmount = _userAmount.sub(totalMissingAmountForWithdraw);
                totalMissingAmountForWithdraw = 0;
            } else {
                mvAmount = 0;
                totalMissingAmountForWithdraw = totalMissingAmountForWithdraw.sub(_userAmount);
            }

            if (mvAmount > 0) {
                IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));
                stafiUserDeposit.recycleWithdrawDeposit{value: _userAmount}();
            }

            // distribute withdrawals
            IStafiDistributor stafiDistributor = IStafiDistributor(getContractAddress("stafiDistributor"));
            uint256 nodeAndPlatformAmount = _nodeAmount.add(_platformAmount);
            stafiDistributor.distributeWithdrawals{value: nodeAndPlatformAmount}();

            afterExecProposal(proposalId);
        }
    }

    function notifyValidatorExit(
        uint256 _withdrawCycle,
        uint256 _ejectedStartCycle,
        uint256[] calldata _validatorIndexList
    ) external override onlyLatestContract("stafiWithdraw", address(this)) onlyTrustedNode(msg.sender) {
        bytes32 proposalId = keccak256(abi.encodePacked(_withdrawCycle, _ejectedStartCycle, _validatorIndexList));
        bool needExe = voteProposal(proposalId);

        // Finalize if Threshold has been reached
        if (needExe) {
            ejectedValidatorsAtCycle[_withdrawCycle] = _validatorIndexList;
            ejectedStartCyle = _ejectedStartCycle;

            emit NotifyValidatorExit(_withdrawCycle, _ejectedStartCycle, _validatorIndexList);

            afterExecProposal(proposalId);
        }
    }

    // ------------ setting ------------
    function setWithdrawCycleLimit(uint256 _withdrawCycleLimit) external onlySuperUser {
        withdrawCycleLimit = _withdrawCycleLimit;
    }

    // ------------ getter ------------
    function getUnclaimedWithdrawalsOfUser(address user) external view returns (uint256[] memory) {
        return getWithdrawalsOfUser(unclaimedWithdrawalsOfUser[user]);
    }

    function getClaimedWithdrawalsOfUser(address user) external view returns (uint256[] memory) {
        return getWithdrawalsOfUser(claimedWithdrawalsOfUser[user]);
    }

    function getWithdrawalsOfUser(
        EnumerableSet.UintSet storage withdrawalsSet
    ) internal view returns (uint256[] memory) {
        uint256 length = withdrawalsSet.length();
        uint256[] memory withdrawals = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            withdrawals[i] = (withdrawalsSet.at(i));
        }
        return withdrawals;
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

        ERC20Burnable(rEthAddress).burnFrom(msg.sender, _rEthAmount);

        return ethAmount;
    }

    function voteProposal(
        bytes32 _proposalId
    ) internal onlyLatestContract("stafiWithdraw", address(this)) onlyTrustedNode(msg.sender) returns (bool) {
        // Get submission keys
        bytes32 proposalNodeKey = keccak256(
            abi.encodePacked("stafiWithdraw.proposal.node.key", _proposalId, msg.sender)
        );
        bytes32 proposalKey = keccak256(abi.encodePacked("stafiWithdraw.proposal.key", _proposalId));

        require(!getBool(proposalKey), "proposal already executed");

        // Check & update node submission status
        require(!getBool(proposalNodeKey), "duplicate vote");
        setBool(proposalNodeKey, true);

        // Increment submission count
        uint256 voteCount = getUint(proposalKey).add(1);
        setUint(proposalKey, voteCount);

        // Check submission count & update network balances
        uint256 calcBase = 1 ether;
        IStafiNodeManager stafiNodeManager = IStafiNodeManager(getContractAddress("stafiNodeManager"));
        IStafiNetworkSettings stafiNetworkSettings = IStafiNetworkSettings(getContractAddress("stafiNetworkSettings"));
        uint256 threshold = stafiNetworkSettings.getNodeConsensusThreshold();
        if (calcBase.mul(voteCount) >= stafiNodeManager.getTrustedNodeCount().mul(threshold)) {
            return true;
        }
        return false;
    }

    function afterExecProposal(bytes32 _proposalId) internal {
        bytes32 proposalKey = keccak256(abi.encodePacked("stafiWithdraw.proposal.key", _proposalId));
        setBool(proposalKey, true);
        emit ProposalExecuted(_proposalId);
    }
}
