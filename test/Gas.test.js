var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
const { ethers, web3 } = require("hardhat")
const { expect } = require("chai")
const { time, beacon } = require("./utilities")
var balance_tree_1 = __importDefault(require("./src/balance-tree"));

describe("StafiDeposit", function () {
    before(async function () {
        this.signers = await ethers.getSigners()

        this.AccountAdmin = this.signers[0]
        this.AccountUser1 = this.signers[1]
        this.AccountNode1 = this.signers[2]
        this.AccountTrustNode1 = this.signers[3]
        this.AccountWithdrawer1 = this.signers[4]
        this.AccountUser2 = this.signers[5]
        this.AccountSuperNode1 = this.signers[6]
        this.AccountNode2 = this.signers[7]
        this.AccountNode3 = this.signers[8]



        this.FactoryStafiNodeDeposit = await ethers.getContractFactory("StafiNodeDeposit", this.AccountAdmin)
        this.FactoryStafiUserDeposit = await ethers.getContractFactory("StafiUserDeposit", this.AccountAdmin)

        this.FactoryStafiNetworkBalances = await ethers.getContractFactory("StafiNetworkBalances", this.AccountAdmin)
        this.FactoryStafiNetworkWithdrawal = await ethers.getContractFactory("StafiNetworkWithdrawal", this.AccountAdmin)
        this.FactoryStafiDistributor = await ethers.getContractFactory("StafiDistributor", this.AccountAdmin)
        this.FactoryStafiFeePool = await ethers.getContractFactory("StafiFeePool", this.AccountAdmin)
        this.FactoryStafiSuperNodeFeePool = await ethers.getContractFactory("StafiSuperNodeFeePool", this.AccountAdmin)

        this.FactoryStafiNodeManager = await ethers.getContractFactory("StafiNodeManager", this.AccountAdmin)
        this.FactoryStafiSuperNode = await ethers.getContractFactory("StafiSuperNode", this.AccountAdmin)
        this.FactoryStafiLightNode = await ethers.getContractFactory("StafiLightNode", this.AccountAdmin)

        this.FactoryStafiStakingPoolQueue = await ethers.getContractFactory("StafiStakingPoolQueue", this.AccountAdmin)
        this.FactoryStafiStakingPoolManager = await ethers.getContractFactory("StafiStakingPoolManager", this.AccountAdmin)
        this.FactoryStafiStakingPoolDelegate = await ethers.getContractFactory("StafiStakingPoolDelegate", this.AccountAdmin)

        this.FactoryStafiNetworkSettings = await ethers.getContractFactory("StafiNetworkSettings", this.AccountAdmin)
        this.FactoryStafiStakingPoolSettings = await ethers.getContractFactory("StafiStakingPoolSettings", this.AccountAdmin)


        this.FactoryStafiStorage = await ethers.getContractFactory("StafiStorage", this.AccountAdmin)
        this.FactoryAddressSetStorage = await ethers.getContractFactory("AddressSetStorage", this.AccountAdmin)
        this.FactoryPubkeySetStorage = await ethers.getContractFactory("PubkeySetStorage", this.AccountAdmin)
        this.FactoryAddressQueueStorage = await ethers.getContractFactory("AddressQueueStorage", this.AccountAdmin)

        this.FactoryDepositContract = await ethers.getContractFactory("DepositContract", this.AccountAdmin)

        this.FactoryRETHToken = await ethers.getContractFactory("RETHToken", this.AccountAdmin)

        this.FactoryStafiEther = await ethers.getContractFactory("StafiEther", this.AccountAdmin)
        this.FactoryStafiUpgrade = await ethers.getContractFactory("StafiUpgrade", this.AccountAdmin)
    })

    beforeEach(async function () {
        this.ContractStafiStorage = await this.FactoryStafiStorage.deploy()
        await this.ContractStafiStorage.deployed()
        // console.log("contract stafiStorate address: ", this.ContractStafiStorage.address)

        this.ContractStafiUpgrade = await this.FactoryStafiUpgrade.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiUpgrade.deployed()
        // console.log("contract stafiUpgrade address: ", this.ContractStafiUpgrade.address)
        await this.ContractStafiUpgrade.initThisContract()



        this.ContractStafiEther = await this.FactoryStafiEther.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiEther.deployed()
        // console.log("contract stafiEther address: ", this.ContractStafiEther.address)
        await this.ContractStafiUpgrade.addContract("stafiEther", this.ContractStafiEther.address)


        this.ContractDepositContract = await this.FactoryDepositContract.deploy()
        await this.ContractDepositContract.deployed()
        // console.log("contract depositContract address: ", this.ContractDepositContract.address)
        await this.ContractStafiUpgrade.addContract("ethDeposit", this.ContractDepositContract.address)


        this.ContractRETHToken = await this.FactoryRETHToken.deploy(this.ContractStafiStorage.address)
        await this.ContractRETHToken.deployed()
        // console.log("contract RETHToken address: ", this.ContractRETHToken.address)
        await this.ContractStafiUpgrade.addContract("rETHToken", this.ContractRETHToken.address)


        this.ContractAddressSetStorage = await this.FactoryAddressSetStorage.deploy(this.ContractStafiStorage.address)
        await this.ContractAddressSetStorage.deployed()
        // console.log("contract addressSetStorage address: ", this.ContractAddressSetStorage.address)
        await this.ContractStafiUpgrade.addContract("addressSetStorage", this.ContractAddressSetStorage.address)

        this.ContractPubkeySetStorage = await this.FactoryPubkeySetStorage.deploy(this.ContractStafiStorage.address)
        await this.ContractPubkeySetStorage.deployed()
        // console.log("contract pubkeySetStorage address: ", this.ContractPubkeySetStorage.address)
        await this.ContractStafiUpgrade.addContract("pubkeySetStorage", this.ContractPubkeySetStorage.address)

        this.ContractAddressQueueStorage = await this.FactoryAddressQueueStorage.deploy(this.ContractStafiStorage.address)
        await this.ContractAddressQueueStorage.deployed()
        // console.log("contract addressQueueStorage address: ", this.ContractAddressQueueStorage.address)
        await this.ContractStafiUpgrade.addContract("addressQueueStorage", this.ContractAddressQueueStorage.address)



        this.ContractStafiNetworkSettings = await this.FactoryStafiNetworkSettings.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiNetworkSettings.deployed()
        // console.log("contract stafiNetworkSettings address: ", this.ContractStafiNetworkSettings.address)
        await this.ContractStafiUpgrade.addContract("stafiNetworkSettings", this.ContractStafiNetworkSettings.address)

        this.ContractStafiStakingPoolSettings = await this.FactoryStafiStakingPoolSettings.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiStakingPoolSettings.deployed()
        // console.log("contract stafiStakingPoolSettings address: ", this.ContractStafiStakingPoolSettings.address)
        await await this.ContractStafiUpgrade.addContract("stafiStakingPoolSettings", this.ContractStafiStakingPoolSettings.address)


        this.ContractStafiStakingPoolQueue = await this.FactoryStafiStakingPoolQueue.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiStakingPoolQueue.deployed()
        // console.log("contract stafiStakingPoolQueue address: ", this.ContractStafiStakingPoolQueue.address)
        await this.ContractStafiUpgrade.addContract("stafiStakingPoolQueue", this.ContractStafiStakingPoolQueue.address)

        this.ContractStafiStakingPoolManager = await this.FactoryStafiStakingPoolManager.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiStakingPoolManager.deployed()
        // console.log("contract stafiStakingPoolManager address: ", this.ContractStafiStakingPoolManager.address)
        await this.ContractStafiUpgrade.addContract("stafiStakingPoolManager", this.ContractStafiStakingPoolManager.address)

        this.ContractStafiStakingPoolDelegate = await this.FactoryStafiStakingPoolDelegate.deploy()
        await this.ContractStafiStakingPoolDelegate.deployed()
        // console.log("contract stafiStakingPoolDelegate address: ", this.ContractStafiStakingPoolDelegate.address)
        await this.ContractStafiUpgrade.addContract("stafiStakingPoolDelegate", this.ContractStafiStakingPoolDelegate.address)



        this.ContractStafiNodeManager = await this.FactoryStafiNodeManager.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiNodeManager.deployed()
        // console.log("contract stafiNodeManager address: ", this.ContractStafiNodeManager.address)
        await this.ContractStafiUpgrade.addContract("stafiNodeManager", this.ContractStafiNodeManager.address)

        this.ContractStafiSuperNode = await this.FactoryStafiSuperNode.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiSuperNode.deployed()
        // console.log("contract stafiSuperNode address: ", this.ContractStafiSuperNode.address)
        await this.ContractStafiUpgrade.addContract("stafiSuperNode", this.ContractStafiSuperNode.address)

        this.ContractStafiLightNode = await this.FactoryStafiLightNode.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiLightNode.deployed()
        // console.log("contract stafiLightNode address: ", this.ContractStafiLightNode.address)
        await this.ContractStafiUpgrade.addContract("stafiLightNode", this.ContractStafiLightNode.address)


        this.ContractStafiNetworkBalances = await this.FactoryStafiNetworkBalances.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiNetworkBalances.deployed()
        // console.log("contract stafiNetworkBalances address: ", this.ContractStafiNetworkBalances.address)
        await this.ContractStafiUpgrade.addContract("stafiNetworkBalances", this.ContractStafiNetworkBalances.address)

        this.ContractStafiNetworkWithdrawal = await this.FactoryStafiNetworkWithdrawal.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiNetworkWithdrawal.deployed()
        // console.log("contract stafiNetworkWithdrawal address: ", this.ContractStafiNetworkWithdrawal.address)
        await this.ContractStafiUpgrade.addContract("stafiNetworkWithdrawal", this.ContractStafiNetworkWithdrawal.address)

        this.ContractStafiDistributor = await this.FactoryStafiDistributor.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiDistributor.deployed()
        // console.log("contract stafi distributor address: ", this.ContractStafiDistributor.address)
        await this.ContractStafiUpgrade.addContract("stafiDistributor", this.ContractStafiDistributor.address)

        this.ContractStafiFeePool = await this.FactoryStafiFeePool.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiFeePool.deployed()
        // console.log("contract stafi fee pool address: ", this.ContractStafiFeePool.address)
        await this.ContractStafiUpgrade.addContract("stafiFeePool", this.ContractStafiFeePool.address)

        this.ContractStafiSuperNodeFeePool = await this.FactoryStafiSuperNodeFeePool.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiSuperNodeFeePool.deployed()
        // console.log("contract stafi super node fee pool address: ", this.ContractStafiSuperNodeFeePool.address)
        await this.ContractStafiUpgrade.addContract("stafiSuperNodeFeePool", this.ContractStafiSuperNodeFeePool.address)



        this.ContracStafiNodeDeposit = await this.FactoryStafiNodeDeposit.deploy(this.ContractStafiStorage.address)
        await this.ContracStafiNodeDeposit.deployed()
        // console.log("contract stafiNodeDeposit address: ", this.ContracStafiNodeDeposit.address)
        await this.ContractStafiUpgrade.addContract("stafiNodeDeposit", this.ContracStafiNodeDeposit.address)

        this.ContractStafiUserDeposit = await this.FactoryStafiUserDeposit.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiUserDeposit.deployed()
        // console.log("contract stafiUserDeposit address: ", this.ContractStafiUserDeposit.address)
        await this.ContractStafiUpgrade.addContract("stafiUserDeposit", this.ContractStafiUserDeposit.address)



        await this.ContractStafiUpgrade.initStorage(true)

        this.WithdrawalCredentials = '0x003cd051a5757b82bf2c399d7476d1636473969af698377434af1d6c54f2bee9'
        await this.ContractStafiNetworkSettings.setWithdrawalCredentials(this.WithdrawalCredentials)

        await this.ContractStafiNodeManager.connect(this.AccountAdmin).setNodeTrusted(this.AccountTrustNode1.address, true)
        await this.ContractStafiNodeManager.connect(this.AccountAdmin).setNodeSuper(this.AccountSuperNode1.address, true)

    })

    it("light node deposit/stake gas(1)", async function () {
        // console.log("latest block: ", await time.latestBlock())
        // enable deposit
        await this.ContractStafiLightNode.connect(this.AccountAdmin).setLightNodeDepositEnabled(true)
        // user deposit
        let userDepositTx = await this.ContractStafiUserDeposit.connect(this.AccountUser1).deposit({ from: this.AccountUser1.address, value: web3.utils.toWei('200', 'ether') })
        let userDepositTxRecipient = await userDepositTx.wait()
        // console.log("user deposit tx gas: ", userDepositTxRecipient.gasUsed.toString())

        // node deposit
        let depositDataInDeposit1 = {
            pubkey: beacon.getValidatorPubkey(),
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(4000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };

        let depositDataInDepositRoot1 = beacon.getDepositDataRoot(depositDataInDeposit1);

        let nodeDepositTx = await this.ContractStafiLightNode.connect(this.AccountUser2).deposit(
            [depositDataInDeposit1.pubkey],
            [depositDataInDeposit1.signature],
            [depositDataInDepositRoot1],
            { from: this.AccountUser2.address, value: web3.utils.toWei('4', 'ether') })

        let nodeDepositTxRecipient = await nodeDepositTx.wait()
        console.log("light node deposit tx gas: ", nodeDepositTxRecipient.gasUsed.toString())

        // trust node vote withdrawCredentials
        await this.ContractStafiLightNode.connect(this.AccountTrustNode1).voteWithdrawCredentials([depositDataInDeposit1.pubkey], [true])

        // node stake
        let depositDataInStake1 = {
            pubkey: depositDataInDeposit1.pubkey,
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(28000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };

        let depositDataInStakeRoot1 = beacon.getDepositDataRoot(depositDataInStake1);

        let nodeStakeTx = await this.ContractStafiLightNode.connect(this.AccountUser2).stake(
            [depositDataInStake1.pubkey],
            [depositDataInStake1.signature],
            [depositDataInStakeRoot1])

        let nodeStakeTxRecipient = await nodeStakeTx.wait()
        console.log("light node stake tx gas: ", nodeStakeTxRecipient.gasUsed.toString())
    })

    it("light node deposit/stake gas(2)", async function () {
        // console.log("latest block: ", await time.latestBlock())
        // enable deposit
        await this.ContractStafiLightNode.connect(this.AccountAdmin).setLightNodeDepositEnabled(true)
        // user deposit
        let userDepositTx = await this.ContractStafiUserDeposit.connect(this.AccountUser1).deposit({ from: this.AccountUser1.address, value: web3.utils.toWei('200', 'ether') })
        let userDepositTxRecipient = await userDepositTx.wait()
        // console.log("user deposit tx gas: ", userDepositTxRecipient.gasUsed.toString())

        // node deposit
        let depositDataInDeposit1 = {
            pubkey: beacon.getValidatorPubkey(),
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(4000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };

        let depositDataInDeposit2 = {
            pubkey: beacon.getValidatorPubkey(),
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(4000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };
        let depositDataInDepositRoot1 = beacon.getDepositDataRoot(depositDataInDeposit1);
        let depositDataInDepositRoot2 = beacon.getDepositDataRoot(depositDataInDeposit2);

        let nodeDepositTx = await this.ContractStafiLightNode.connect(this.AccountUser2).deposit(
            [depositDataInDeposit1.pubkey, depositDataInDeposit2.pubkey],
            [depositDataInDeposit1.signature, depositDataInDeposit2.signature],
            [depositDataInDepositRoot1, depositDataInDepositRoot2],
            { from: this.AccountUser2.address, value: web3.utils.toWei('8', 'ether') })

        let nodeDepositTxRecipient = await nodeDepositTx.wait()
        console.log("light node deposit tx gas: ", nodeDepositTxRecipient.gasUsed.toString())

        // trust node vote withdrawCredentials
        await this.ContractStafiLightNode.connect(this.AccountTrustNode1).voteWithdrawCredentials([depositDataInDeposit1.pubkey, depositDataInDeposit2.pubkey], [true, true])

        // node stake
        let depositDataInStake1 = {
            pubkey: depositDataInDeposit1.pubkey,
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(28000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };

        let depositDataInStake2 = {
            pubkey: depositDataInDeposit2.pubkey,
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(28000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };
        let depositDataInStakeRoot1 = beacon.getDepositDataRoot(depositDataInStake1);
        let depositDataInStakeRoot2 = beacon.getDepositDataRoot(depositDataInStake2);

        let nodeStakeTx = await this.ContractStafiLightNode.connect(this.AccountUser2).stake(
            [depositDataInStake1.pubkey, depositDataInStake2.pubkey],
            [depositDataInStake1.signature, depositDataInStake2.signature],
            [depositDataInStakeRoot1, depositDataInStakeRoot2])

        let nodeStakeTxRecipient = await nodeStakeTx.wait()
        console.log("light node stake tx gas: ", nodeStakeTxRecipient.gasUsed.toString())
    })
    it("light node deposit/stake gas(3)", async function () {
        // console.log("latest block: ", await time.latestBlock())
        // enable deposit
        await this.ContractStafiLightNode.connect(this.AccountAdmin).setLightNodeDepositEnabled(true)
        // user deposit
        let userDepositTx = await this.ContractStafiUserDeposit.connect(this.AccountUser1).deposit({ from: this.AccountUser1.address, value: web3.utils.toWei('200', 'ether') })
        let userDepositTxRecipient = await userDepositTx.wait()
        // console.log("user deposit tx gas: ", userDepositTxRecipient.gasUsed.toString())

        // node deposit
        let depositDataInDeposit1 = {
            pubkey: beacon.getValidatorPubkey(),
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(4000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };

        let depositDataInDeposit2 = {
            pubkey: beacon.getValidatorPubkey(),
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(4000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };
        let depositDataInDeposit3 = {
            pubkey: beacon.getValidatorPubkey(),
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(4000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };
        let depositDataInDepositRoot1 = beacon.getDepositDataRoot(depositDataInDeposit1);
        let depositDataInDepositRoot2 = beacon.getDepositDataRoot(depositDataInDeposit2);
        let depositDataInDepositRoot3 = beacon.getDepositDataRoot(depositDataInDeposit3);

        let nodeDepositTx = await this.ContractStafiLightNode.connect(this.AccountUser2).deposit(
            [depositDataInDeposit1.pubkey, depositDataInDeposit2.pubkey, depositDataInDeposit3.pubkey],
            [depositDataInDeposit1.signature, depositDataInDeposit2.signature, depositDataInDeposit3.signature],
            [depositDataInDepositRoot1, depositDataInDepositRoot2, depositDataInDepositRoot3],
            { from: this.AccountUser2.address, value: web3.utils.toWei('12', 'ether') })

        let nodeDepositTxRecipient = await nodeDepositTx.wait()
        console.log("light node deposit tx gas: ", nodeDepositTxRecipient.gasUsed.toString())

        // trust node vote withdrawCredentials
        await this.ContractStafiLightNode.connect(this.AccountTrustNode1).voteWithdrawCredentials(
            [depositDataInDeposit1.pubkey,
            depositDataInDeposit2.pubkey,
            depositDataInDeposit3.pubkey],
            [true, true, true])

        // node stake
        let depositDataInStake1 = {
            pubkey: depositDataInDeposit1.pubkey,
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(28000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };

        let depositDataInStake2 = {
            pubkey: depositDataInDeposit2.pubkey,
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(28000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };
        let depositDataInStake3 = {
            pubkey: depositDataInDeposit3.pubkey,
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(28000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };
        let depositDataInStakeRoot1 = beacon.getDepositDataRoot(depositDataInStake1);
        let depositDataInStakeRoot2 = beacon.getDepositDataRoot(depositDataInStake2);
        let depositDataInStakeRoot3 = beacon.getDepositDataRoot(depositDataInStake3);

        let nodeStakeTx = await this.ContractStafiLightNode.connect(this.AccountUser2).stake(
            [depositDataInStake1.pubkey, depositDataInStake2.pubkey, depositDataInStake3.pubkey],
            [depositDataInStake1.signature, depositDataInStake2.signature, depositDataInStake3.signature],
            [depositDataInStakeRoot1, depositDataInStakeRoot2, depositDataInStakeRoot3])

        let nodeStakeTxRecipient = await nodeStakeTx.wait()
        console.log("light node stake tx gas: ", nodeStakeTxRecipient.gasUsed.toString())
    })

    it("light node deposit/stake gas(10)", async function () {
        // console.log("latest block: ", await time.latestBlock())
        // enable deposit
        await this.ContractStafiLightNode.connect(this.AccountAdmin).setLightNodeDepositEnabled(true)
        // user deposit
        let userDepositTx = await this.ContractStafiUserDeposit.connect(this.AccountUser1).deposit({ from: this.AccountUser1.address, value: web3.utils.toWei('600', 'ether') })
        let userDepositTxRecipient = await userDepositTx.wait()
        // console.log("user deposit tx gas: ", userDepositTxRecipient.gasUsed.toString())

        // node deposit
        let len = 10;
        let depositDataInDepositList = new Array();
        let pubkeyList = new Array();
        let sigList = new Array();
        let matchList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInDepositList[i] = {
                pubkey: beacon.getValidatorPubkey(),
                withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
                amount: BigInt(4000000000), // gwei
                signature: beacon.getValidatorSignature(),
            };
            pubkeyList[i] = depositDataInDepositList[i].pubkey
            sigList[i] = depositDataInDepositList[i].signature
            matchList[i] = true
        }

        let depositDataInDepositRootList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInDepositRootList[i] = beacon.getDepositDataRoot(depositDataInDepositList[i]);
        }

        let nodeDepositTx = await this.ContractStafiLightNode.connect(this.AccountUser2).deposit(
            pubkeyList,
            sigList,
            depositDataInDepositRootList,
            { from: this.AccountUser2.address, value: web3.utils.toWei((4 * len).toString(), 'ether') })

        let nodeDepositTxRecipient = await nodeDepositTx.wait()
        console.log("light node deposit tx gas: ", nodeDepositTxRecipient.gasUsed.toString())

        // trust node vote withdrawCredentials
        await this.ContractStafiLightNode.connect(this.AccountTrustNode1).voteWithdrawCredentials(pubkeyList, matchList)

        // node stake
        let depositDataInStakeList = new Array();
        let stakePubkeyList = new Array();
        let stakeSigList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInStakeList[i] = {
                pubkey: depositDataInDepositList[i].pubkey,
                withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
                amount: BigInt(28000000000), // gwei
                signature: beacon.getValidatorSignature(),
            };
            stakePubkeyList[i] = depositDataInStakeList[i].pubkey
            stakeSigList[i] = depositDataInStakeList[i].signature
        }

        let depositDataInStakeRootList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInStakeRootList[i] = beacon.getDepositDataRoot(depositDataInStakeList[i])
        }

        let nodeStakeTx = await this.ContractStafiLightNode.connect(this.AccountUser2).stake(
            stakePubkeyList,
            stakeSigList,
            depositDataInStakeRootList)

        let nodeStakeTxRecipient = await nodeStakeTx.wait()
        console.log("light node stake tx gas: ", nodeStakeTxRecipient.gasUsed.toString())
    })
    it("light node deposit/stake gas(20)", async function () {
        // console.log("latest block: ", await time.latestBlock())
        // enable deposit
        await this.ContractStafiLightNode.connect(this.AccountAdmin).setLightNodeDepositEnabled(true)
        // user deposit
        let userDepositTx = await this.ContractStafiUserDeposit.connect(this.AccountUser1).deposit({ from: this.AccountUser1.address, value: web3.utils.toWei('600', 'ether') })
        let userDepositTxRecipient = await userDepositTx.wait()
        // console.log("user deposit tx gas: ", userDepositTxRecipient.gasUsed.toString())

        // node deposit
        let len = 20;
        let depositDataInDepositList = new Array();
        let pubkeyList = new Array();
        let sigList = new Array();
        let matchList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInDepositList[i] = {
                pubkey: beacon.getValidatorPubkey(),
                withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
                amount: BigInt(4000000000), // gwei
                signature: beacon.getValidatorSignature(),
            };
            pubkeyList[i] = depositDataInDepositList[i].pubkey
            sigList[i] = depositDataInDepositList[i].signature
            matchList[i] = true
        }

        let depositDataInDepositRootList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInDepositRootList[i] = beacon.getDepositDataRoot(depositDataInDepositList[i]);
        }

        let nodeDepositTx = await this.ContractStafiLightNode.connect(this.AccountUser2).deposit(
            pubkeyList,
            sigList,
            depositDataInDepositRootList,
            { from: this.AccountUser2.address, value: web3.utils.toWei((4 * len).toString(), 'ether') })

        let nodeDepositTxRecipient = await nodeDepositTx.wait()
        console.log("light node deposit tx gas: ", nodeDepositTxRecipient.gasUsed.toString())

        // trust node vote withdrawCredentials
        await this.ContractStafiLightNode.connect(this.AccountTrustNode1).voteWithdrawCredentials(pubkeyList, matchList)

        // node stake
        let depositDataInStakeList = new Array();
        let stakePubkeyList = new Array();
        let stakeSigList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInStakeList[i] = {
                pubkey: depositDataInDepositList[i].pubkey,
                withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
                amount: BigInt(28000000000), // gwei
                signature: beacon.getValidatorSignature(),
            };
            stakePubkeyList[i] = depositDataInStakeList[i].pubkey
            stakeSigList[i] = depositDataInStakeList[i].signature
        }

        let depositDataInStakeRootList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInStakeRootList[i] = beacon.getDepositDataRoot(depositDataInStakeList[i])
        }

        let nodeStakeTx = await this.ContractStafiLightNode.connect(this.AccountUser2).stake(
            stakePubkeyList,
            stakeSigList,
            depositDataInStakeRootList)

        let nodeStakeTxRecipient = await nodeStakeTx.wait()
        console.log("light node stake tx gas: ", nodeStakeTxRecipient.gasUsed.toString())
    })





    it("super node deposit/stake gas(1)", async function () {
        // console.log("latest block: ", await time.latestBlock())
        // enable deposit
        await this.ContractStafiSuperNode.connect(this.AccountAdmin).setSuperNodeDepositEnabled(true)
        // user deposit
        let userDepositTx = await this.ContractStafiUserDeposit.connect(this.AccountUser1).deposit({ from: this.AccountUser1.address, value: web3.utils.toWei('800', 'ether') })
        let userDepositTxRecipient = await userDepositTx.wait()
        // console.log("user deposit tx gas: ", userDepositTxRecipient.gasUsed.toString())

        // node deposit
        let len = 1;
        let depositDataInDepositList = new Array();
        let pubkeyList = new Array();
        let sigList = new Array();
        let matchList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInDepositList[i] = {
                pubkey: beacon.getValidatorPubkey(),
                withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
                amount: BigInt(1000000000), // gwei
                signature: beacon.getValidatorSignature(),
            };
            pubkeyList[i] = depositDataInDepositList[i].pubkey
            sigList[i] = depositDataInDepositList[i].signature
            matchList[i] = true
        }

        let depositDataInDepositRootList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInDepositRootList[i] = beacon.getDepositDataRoot(depositDataInDepositList[i]);
        }

        let nodeDepositTx = await this.ContractStafiSuperNode.connect(this.AccountSuperNode1).deposit(
            pubkeyList,
            sigList,
            depositDataInDepositRootList)

        let nodeDepositTxRecipient = await nodeDepositTx.wait()
        console.log("super node deposit tx gas: ", nodeDepositTxRecipient.gasUsed.toString())

        // trust node vote withdrawCredentials
        await this.ContractStafiSuperNode.connect(this.AccountTrustNode1).voteWithdrawCredentials(pubkeyList, matchList)

        // node stake
        let depositDataInStakeList = new Array();
        let stakePubkeyList = new Array();
        let stakeSigList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInStakeList[i] = {
                pubkey: depositDataInDepositList[i].pubkey,
                withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
                amount: BigInt(31000000000), // gwei
                signature: beacon.getValidatorSignature(),
            };
            stakePubkeyList[i] = depositDataInStakeList[i].pubkey
            stakeSigList[i] = depositDataInStakeList[i].signature
        }

        let depositDataInStakeRootList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInStakeRootList[i] = beacon.getDepositDataRoot(depositDataInStakeList[i])
        }

        let nodeStakeTx = await this.ContractStafiSuperNode.connect(this.AccountSuperNode1).stake(
            stakePubkeyList,
            stakeSigList,
            depositDataInStakeRootList)

        let nodeStakeTxRecipient = await nodeStakeTx.wait()
        console.log("super node stake tx gas: ", nodeStakeTxRecipient.gasUsed.toString())
    })
    it("super node deposit/stake gas(2)", async function () {
        // console.log("latest block: ", await time.latestBlock())
        // enable deposit
        await this.ContractStafiSuperNode.connect(this.AccountAdmin).setSuperNodeDepositEnabled(true)
        // user deposit
        let userDepositTx = await this.ContractStafiUserDeposit.connect(this.AccountUser1).deposit({ from: this.AccountUser1.address, value: web3.utils.toWei('800', 'ether') })
        let userDepositTxRecipient = await userDepositTx.wait()
        // console.log("user deposit tx gas: ", userDepositTxRecipient.gasUsed.toString())

        // node deposit
        let len = 2;
        let depositDataInDepositList = new Array();
        let pubkeyList = new Array();
        let sigList = new Array();
        let matchList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInDepositList[i] = {
                pubkey: beacon.getValidatorPubkey(),
                withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
                amount: BigInt(1000000000), // gwei
                signature: beacon.getValidatorSignature(),
            };
            pubkeyList[i] = depositDataInDepositList[i].pubkey
            sigList[i] = depositDataInDepositList[i].signature
            matchList[i] = true
        }

        let depositDataInDepositRootList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInDepositRootList[i] = beacon.getDepositDataRoot(depositDataInDepositList[i]);
        }

        let nodeDepositTx = await this.ContractStafiSuperNode.connect(this.AccountSuperNode1).deposit(
            pubkeyList,
            sigList,
            depositDataInDepositRootList)

        let nodeDepositTxRecipient = await nodeDepositTx.wait()
        console.log("super node deposit tx gas: ", nodeDepositTxRecipient.gasUsed.toString())

        // trust node vote withdrawCredentials
        await this.ContractStafiSuperNode.connect(this.AccountTrustNode1).voteWithdrawCredentials(pubkeyList, matchList)

        // node stake
        let depositDataInStakeList = new Array();
        let stakePubkeyList = new Array();
        let stakeSigList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInStakeList[i] = {
                pubkey: depositDataInDepositList[i].pubkey,
                withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
                amount: BigInt(31000000000), // gwei
                signature: beacon.getValidatorSignature(),
            };
            stakePubkeyList[i] = depositDataInStakeList[i].pubkey
            stakeSigList[i] = depositDataInStakeList[i].signature
        }

        let depositDataInStakeRootList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInStakeRootList[i] = beacon.getDepositDataRoot(depositDataInStakeList[i])
        }

        let nodeStakeTx = await this.ContractStafiSuperNode.connect(this.AccountSuperNode1).stake(
            stakePubkeyList,
            stakeSigList,
            depositDataInStakeRootList)

        let nodeStakeTxRecipient = await nodeStakeTx.wait()
        console.log("super node stake tx gas: ", nodeStakeTxRecipient.gasUsed.toString())
    })

    it("super node deposit/stake gas(3)", async function () {
        // console.log("latest block: ", await time.latestBlock())
        // enable deposit
        await this.ContractStafiSuperNode.connect(this.AccountAdmin).setSuperNodeDepositEnabled(true)
        // user deposit
        let userDepositTx = await this.ContractStafiUserDeposit.connect(this.AccountUser1).deposit({ from: this.AccountUser1.address, value: web3.utils.toWei('800', 'ether') })
        let userDepositTxRecipient = await userDepositTx.wait()
        // console.log("user deposit tx gas: ", userDepositTxRecipient.gasUsed.toString())

        // node deposit
        let len = 3;
        let depositDataInDepositList = new Array();
        let pubkeyList = new Array();
        let sigList = new Array();
        let matchList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInDepositList[i] = {
                pubkey: beacon.getValidatorPubkey(),
                withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
                amount: BigInt(1000000000), // gwei
                signature: beacon.getValidatorSignature(),
            };
            pubkeyList[i] = depositDataInDepositList[i].pubkey
            sigList[i] = depositDataInDepositList[i].signature
            matchList[i] = true
        }

        let depositDataInDepositRootList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInDepositRootList[i] = beacon.getDepositDataRoot(depositDataInDepositList[i]);
        }

        let nodeDepositTx = await this.ContractStafiSuperNode.connect(this.AccountSuperNode1).deposit(
            pubkeyList,
            sigList,
            depositDataInDepositRootList)

        let nodeDepositTxRecipient = await nodeDepositTx.wait()
        console.log("super node deposit tx gas: ", nodeDepositTxRecipient.gasUsed.toString())

        // trust node vote withdrawCredentials
        await this.ContractStafiSuperNode.connect(this.AccountTrustNode1).voteWithdrawCredentials(pubkeyList, matchList)

        // node stake
        let depositDataInStakeList = new Array();
        let stakePubkeyList = new Array();
        let stakeSigList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInStakeList[i] = {
                pubkey: depositDataInDepositList[i].pubkey,
                withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
                amount: BigInt(31000000000), // gwei
                signature: beacon.getValidatorSignature(),
            };
            stakePubkeyList[i] = depositDataInStakeList[i].pubkey
            stakeSigList[i] = depositDataInStakeList[i].signature
        }

        let depositDataInStakeRootList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInStakeRootList[i] = beacon.getDepositDataRoot(depositDataInStakeList[i])
        }

        let nodeStakeTx = await this.ContractStafiSuperNode.connect(this.AccountSuperNode1).stake(
            stakePubkeyList,
            stakeSigList,
            depositDataInStakeRootList)

        let nodeStakeTxRecipient = await nodeStakeTx.wait()
        console.log("super node stake tx gas: ", nodeStakeTxRecipient.gasUsed.toString())
    })

    it("super node deposit/stake gas(10)", async function () {
        // console.log("latest block: ", await time.latestBlock())
        // enable deposit
        await this.ContractStafiSuperNode.connect(this.AccountAdmin).setSuperNodeDepositEnabled(true)
        // user deposit
        let userDepositTx = await this.ContractStafiUserDeposit.connect(this.AccountUser1).deposit({ from: this.AccountUser1.address, value: web3.utils.toWei('800', 'ether') })
        let userDepositTxRecipient = await userDepositTx.wait()
        // console.log("user deposit tx gas: ", userDepositTxRecipient.gasUsed.toString())

        // node deposit
        let len = 10;
        let depositDataInDepositList = new Array();
        let pubkeyList = new Array();
        let sigList = new Array();
        let matchList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInDepositList[i] = {
                pubkey: beacon.getValidatorPubkey(),
                withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
                amount: BigInt(1000000000), // gwei
                signature: beacon.getValidatorSignature(),
            };
            pubkeyList[i] = depositDataInDepositList[i].pubkey
            sigList[i] = depositDataInDepositList[i].signature
            matchList[i] = true
        }

        let depositDataInDepositRootList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInDepositRootList[i] = beacon.getDepositDataRoot(depositDataInDepositList[i]);
        }

        let nodeDepositTx = await this.ContractStafiSuperNode.connect(this.AccountSuperNode1).deposit(
            pubkeyList,
            sigList,
            depositDataInDepositRootList)

        let nodeDepositTxRecipient = await nodeDepositTx.wait()
        console.log("super node deposit tx gas: ", nodeDepositTxRecipient.gasUsed.toString())

        // trust node vote withdrawCredentials
        await this.ContractStafiSuperNode.connect(this.AccountTrustNode1).voteWithdrawCredentials(pubkeyList, matchList)

        // node stake
        let depositDataInStakeList = new Array();
        let stakePubkeyList = new Array();
        let stakeSigList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInStakeList[i] = {
                pubkey: depositDataInDepositList[i].pubkey,
                withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
                amount: BigInt(31000000000), // gwei
                signature: beacon.getValidatorSignature(),
            };
            stakePubkeyList[i] = depositDataInStakeList[i].pubkey
            stakeSigList[i] = depositDataInStakeList[i].signature
        }

        let depositDataInStakeRootList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInStakeRootList[i] = beacon.getDepositDataRoot(depositDataInStakeList[i])
        }

        let nodeStakeTx = await this.ContractStafiSuperNode.connect(this.AccountSuperNode1).stake(
            stakePubkeyList,
            stakeSigList,
            depositDataInStakeRootList)

        let nodeStakeTxRecipient = await nodeStakeTx.wait()
        console.log("super node stake tx gas: ", nodeStakeTxRecipient.gasUsed.toString())
    })

    it("super node deposit/stake gas(20)", async function () {
        // console.log("latest block: ", await time.latestBlock())
        // enable deposit
        await this.ContractStafiSuperNode.connect(this.AccountAdmin).setSuperNodeDepositEnabled(true)
        // user deposit
        let userDepositTx = await this.ContractStafiUserDeposit.connect(this.AccountUser1).deposit({ from: this.AccountUser1.address, value: web3.utils.toWei('800', 'ether') })
        let userDepositTxRecipient = await userDepositTx.wait()
        // console.log("user deposit tx gas: ", userDepositTxRecipient.gasUsed.toString())

        // node deposit
        let len = 20;
        let depositDataInDepositList = new Array();
        let pubkeyList = new Array();
        let sigList = new Array();
        let matchList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInDepositList[i] = {
                pubkey: beacon.getValidatorPubkey(),
                withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
                amount: BigInt(1000000000), // gwei
                signature: beacon.getValidatorSignature(),
            };
            pubkeyList[i] = depositDataInDepositList[i].pubkey
            sigList[i] = depositDataInDepositList[i].signature
            matchList[i] = true
        }

        let depositDataInDepositRootList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInDepositRootList[i] = beacon.getDepositDataRoot(depositDataInDepositList[i]);
        }

        let nodeDepositTx = await this.ContractStafiSuperNode.connect(this.AccountSuperNode1).deposit(
            pubkeyList,
            sigList,
            depositDataInDepositRootList)

        let nodeDepositTxRecipient = await nodeDepositTx.wait()
        console.log("super node deposit tx gas: ", nodeDepositTxRecipient.gasUsed.toString())

        // trust node vote withdrawCredentials
        await this.ContractStafiSuperNode.connect(this.AccountTrustNode1).voteWithdrawCredentials(pubkeyList, matchList)

        // node stake
        let depositDataInStakeList = new Array();
        let stakePubkeyList = new Array();
        let stakeSigList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInStakeList[i] = {
                pubkey: depositDataInDepositList[i].pubkey,
                withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
                amount: BigInt(31000000000), // gwei
                signature: beacon.getValidatorSignature(),
            };
            stakePubkeyList[i] = depositDataInStakeList[i].pubkey
            stakeSigList[i] = depositDataInStakeList[i].signature
        }

        let depositDataInStakeRootList = new Array();
        for (i = 0; i < len; i++) {
            depositDataInStakeRootList[i] = beacon.getDepositDataRoot(depositDataInStakeList[i])
        }

        let nodeStakeTx = await this.ContractStafiSuperNode.connect(this.AccountSuperNode1).stake(
            stakePubkeyList,
            stakeSigList,
            depositDataInStakeRootList)

        let nodeStakeTxRecipient = await nodeStakeTx.wait()
        console.log("super node stake tx gas: ", nodeStakeTxRecipient.gasUsed.toString())
    })
})