pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only
import "../interfaces/storage/IStafiStorage.sol";
import "../types/DepositType.sol";
import "../types/StakingPoolStatus.sol";

// An individual staking pool
abstract contract StafiStakingPoolStorage {
    // Storage state enum
    enum StorageState {
        Undefined,
        Uninitialised,
        Initialised
    }
    // Main storage contract
    IStafiStorage internal stafiStorage = IStafiStorage(0);

    // Status
    StakingPoolStatus internal status;
    uint256 internal statusBlock;
    uint256 internal statusTime;

    // withdrawalCredentials is match
    bool internal withdrawalCredentialsMatch;

    // Deposit type
    DepositType internal depositType;

    // Node details
    address internal nodeAddress;
    uint256 internal nodeFee;
    uint256 internal nodeDepositBalance;
    bool internal nodeDepositAssigned;
    uint256 internal nodeRefundBalance;
    bool internal nodeCommonlyRefunded;
    bool internal nodeTrustedRefunded;

    // User deposit details
    uint256 internal userDepositBalance;
    bool internal userDepositAssigned;
    uint256 internal userDepositAssignedTime;

    // Upgrade options
    bool internal useLatestDelegate = false;
    address internal stafiStakingPoolDelegate;
    address internal stafiStakingPoolDelegatePrev;

    // Platform details
    uint256 internal platformDepositBalance;

    // Used to prevent direct access to delegate and prevent calling initialise more than once
    StorageState storageState = StorageState.Undefined;

    // Trusted member  votes
    mapping(address => bool) memberVotes;
    uint256 totalVotes;
}
