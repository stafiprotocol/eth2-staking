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
    }

    uint256 public nextWithdrawIndex;
    uint256 public maxClaimableWithdrawIndex;
    uint256 public ejectedStartCycle;
    uint256 public latestDistributeHeight;
    uint256 public totalMissingAmountForWithdraw;
    uint256 public withdrawLimitPerCycle;
    uint256 public userWithdrawLimitPerCycle;

    mapping(uint256 => Withdrawal) public withdrawalAtIndex;
    mapping(address => EnumerableSet.UintSet) internal unclaimedWithdrawalsOfUser;
    mapping(uint256 => uint256) public totalWithdrawAmountAtCycle;
    mapping(address => mapping(uint256 => uint256)) public userWithdrawAmountAtCycle;
    mapping(uint256 => uint256[]) public ejectedValidatorsAtCycle;

    // ------------ events ------------
    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event Unstake(address indexed from, uint256 rethAmount, uint256 ethAmount, uint256 withdrawIndex, bool instantly);
    event Withdraw(address indexed from, uint256[] withdrawIndexList);
    event VoteProposal(bytes32 indexed proposalId, address voter);
    event ProposalExecuted(bytes32 indexed proposalId);
    event NotifyValidatorExit(uint256 withdrawCycle, uint256 ejectedStartWithdrawCycle, uint256[] ejectedValidators);

    constructor() StafiBase(address(0)) {
        // By setting the version it is not possible to call setup anymore,
        // so we create a Safe with version 1.
        // This is an unusable Safe, perfect for the singleton
        version = 1;
    }

    function initialize(
        address _stafiStorageAddress,
        uint256 _withdrawLimitPerCycle,
        uint256 _userWithdrawLimitPerCycle
    ) external {
        require(version == 0, "already initizlized");
        // init StafiBase storage
        version = 1;
        stafiStorage = IStafiStorage(_stafiStorageAddress);
        // init StafiWithdraw storage
        withdrawLimitPerCycle = _withdrawLimitPerCycle;
        userWithdrawLimitPerCycle = _userWithdrawLimitPerCycle;
    }

    // Receive eth
    receive() external payable {}

    // Deposit ETH from deposit pool
    // Only accepts calls from the StafiUserDeposit contract
    function depositEth() external payable override onlyLatestContract("stafiUserDeposit", msg.sender) {
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    // ------------ getter ------------

    function getUnclaimedWithdrawalsOfUser(address user) external view override returns (uint256[] memory) {
        uint256 length = unclaimedWithdrawalsOfUser[user].length();
        uint256[] memory withdrawals = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            withdrawals[i] = (unclaimedWithdrawalsOfUser[user].at(i));
        }
        return withdrawals;
    }

    function getEjectedValidatorsAtCycle(uint256 cycle) external view override returns (uint256[] memory) {
        return ejectedValidatorsAtCycle[cycle];
    }

    function currentWithdrawCycle() public view returns (uint256) {
        return block.timestamp.sub(28800).div(86400);
    }

    // ------------ settings ------------

    function setWithdrawLimitPerCycle(uint256 _withdrawLimitPerCycle) external onlySuperUser {
        withdrawLimitPerCycle = _withdrawLimitPerCycle;
    }

    function setUserWithdrawLimitPerCycle(uint256 _userWithdrawLimitPerCycle) external onlySuperUser {
        userWithdrawLimitPerCycle = _userWithdrawLimitPerCycle;
    }

    // ------------ user unstake ------------

    function unstake(uint256 _rEthAmount) external override onlyLatestContract("stafiWithdraw", address(this)) {
        uint256 ethAmount = _processWithdraw(_rEthAmount);
        IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));
        uint256 stakePoolBalance = stafiUserDeposit.getBalance();

        uint256 totalMissingAmount = totalMissingAmountForWithdraw.add(ethAmount);
        if (stakePoolBalance > 0) {
            uint256 mvAmount = totalMissingAmount;
            if (stakePoolBalance < mvAmount) {
                mvAmount = stakePoolBalance;
            }
            stafiUserDeposit.withdrawExcessBalanceForWithdraw(mvAmount);

            totalMissingAmount = totalMissingAmount.sub(mvAmount);
        }
        totalMissingAmountForWithdraw = totalMissingAmount;

        bool unstakeInstantly = totalMissingAmountForWithdraw == 0;
        if (unstakeInstantly) {
            (bool result, ) = msg.sender.call{value: ethAmount}("");
            require(result, "Failed to unstake ETH");
        } else {
            unclaimedWithdrawalsOfUser[msg.sender].add(nextWithdrawIndex);
        }

        emit Unstake(msg.sender, _rEthAmount, ethAmount, nextWithdrawIndex, unstakeInstantly);

        withdrawalAtIndex[nextWithdrawIndex] = Withdrawal({_address: msg.sender, _amount: ethAmount});
        nextWithdrawIndex = nextWithdrawIndex.add(1);
    }

    function withdraw(
        uint256[] calldata _withdrawIndexList
    ) external override onlyLatestContract("stafiWithdraw", address(this)) {
        uint256 totalAmount;
        for (uint256 i = 0; i < _withdrawIndexList.length; i++) {
            uint256 withdrawIndex = _withdrawIndexList[i];
            require(withdrawIndex <= maxClaimableWithdrawIndex, "not claimable");
            require(unclaimedWithdrawalsOfUser[msg.sender].remove(withdrawIndex), "already claimed");

            totalAmount = totalAmount.add(withdrawalAtIndex[withdrawIndex]._amount);
        }

        if (totalAmount > 0) {
            (bool result, ) = msg.sender.call{value: totalAmount}("");
            require(result, "user failed to claim ETH");
        }

        emit Withdraw(msg.sender, _withdrawIndexList);
    }

    // ------------ voter(trust node) ------------

    function distributeWithdrawals(
        uint256 _dealedHeight,
        uint256 _userAmount,
        uint256 _nodeAmount,
        uint256 _platformAmount,
        uint256 _maxClaimableWithdrawIndex
    ) external override onlyLatestContract("stafiWithdraw", address(this)) onlyTrustedNode(msg.sender) {
        require(_dealedHeight > latestDistributeHeight, "height already dealed");
        bytes32 proposalId = keccak256(
            abi.encodePacked(_dealedHeight, _userAmount, _nodeAmount, _platformAmount, _maxClaimableWithdrawIndex)
        );
        bool needExe = _voteProposal(proposalId);

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
                stafiUserDeposit.recycleWithdrawDeposit{value: mvAmount}();
            }

            // distribute withdrawals
            IStafiDistributor stafiDistributor = IStafiDistributor(getContractAddress("stafiDistributor"));
            uint256 nodeAndPlatformAmount = _nodeAmount.add(_platformAmount);
            stafiDistributor.distributeWithdrawals{value: nodeAndPlatformAmount}();

            _afterExecProposal(proposalId);
        }
    }

    function reserveEthForWithdraw(
        uint256 _withdrawCycle
    ) external override onlyLatestContract("stafiWithdraw", address(this)) onlyTrustedNode(msg.sender) {
        bytes32 proposalId = keccak256(abi.encodePacked("reserveEthForWithdraw", _withdrawCycle));
        bool needExe = _voteProposal(proposalId);

        // Finalize if Threshold has been reached
        if (needExe) {
            IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(getContractAddress("stafiUserDeposit"));
            uint256 depositPoolBalance = stafiUserDeposit.getBalance();

            if (depositPoolBalance > 0 && totalMissingAmountForWithdraw > 0) {
                uint256 mvAmount = totalMissingAmountForWithdraw;
                if (depositPoolBalance < mvAmount) {
                    mvAmount = depositPoolBalance;
                }
                stafiUserDeposit.withdrawExcessBalanceForWithdraw(mvAmount);

                totalMissingAmountForWithdraw = totalMissingAmountForWithdraw.sub(mvAmount);
            }
            _afterExecProposal(proposalId);
        }
    }

    function notifyValidatorExit(
        uint256 _withdrawCycle,
        uint256 _ejectedStartCycle,
        uint256[] calldata _validatorIndexList
    ) external override onlyLatestContract("stafiWithdraw", address(this)) onlyTrustedNode(msg.sender) {
        require(_ejectedStartCycle < _withdrawCycle && _withdrawCycle < currentWithdrawCycle(), "cycle not match");

        bytes32 proposalId = keccak256(abi.encodePacked(_withdrawCycle, _ejectedStartCycle, _validatorIndexList));
        bool needExe = _voteProposal(proposalId);

        // Finalize if Threshold has been reached
        if (needExe) {
            ejectedValidatorsAtCycle[_withdrawCycle] = _validatorIndexList;
            ejectedStartCycle = _ejectedStartCycle;

            emit NotifyValidatorExit(_withdrawCycle, _ejectedStartCycle, _validatorIndexList);

            _afterExecProposal(proposalId);
        }
    }

    // ------------ helper ------------

    // check:
    // 1 cycle limit
    // 2 user limit
    // burn reth from user
    // return:
    // 1 eth withdraw amount
    function _processWithdraw(uint256 _rEthAmount) private returns (uint256) {
        require(_rEthAmount > 0, "amount zero");
        address rEthAddress = getContractAddress("rETHToken");
        uint256 ethAmount = IRETHToken(rEthAddress).getEthValue(_rEthAmount);
        uint256 currentCycle = currentWithdrawCycle();
        require(totalWithdrawAmountAtCycle[currentCycle].add(ethAmount) <= withdrawLimitPerCycle, "reach cycle limit");
        require(
            userWithdrawAmountAtCycle[msg.sender][currentCycle].add(ethAmount) <= userWithdrawLimitPerCycle,
            "reach user limit"
        );

        totalWithdrawAmountAtCycle[currentCycle] = totalWithdrawAmountAtCycle[currentCycle].add(ethAmount);
        userWithdrawAmountAtCycle[msg.sender][currentCycle] = userWithdrawAmountAtCycle[msg.sender][currentCycle].add(
            ethAmount
        );

        ERC20Burnable(rEthAddress).burnFrom(msg.sender, _rEthAmount);

        return ethAmount;
    }

    function _voteProposal(bytes32 _proposalId) internal returns (bool) {
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

        emit VoteProposal(_proposalId, msg.sender);

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

    function _afterExecProposal(bytes32 _proposalId) internal {
        bytes32 proposalKey = keccak256(abi.encodePacked("stafiWithdraw.proposal.key", _proposalId));
        setBool(proposalKey, true);

        emit ProposalExecuted(_proposalId);
    }
}
