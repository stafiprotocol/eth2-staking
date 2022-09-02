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
        console.log("contract stafiStorate address: ", this.ContractStafiStorage.address)

        this.ContractStafiUpgrade = await this.FactoryStafiUpgrade.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiUpgrade.deployed()
        console.log("contract stafiUpgrade address: ", this.ContractStafiUpgrade.address)
        await this.ContractStafiUpgrade.initThisContract()



        this.ContractStafiEther = await this.FactoryStafiEther.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiEther.deployed()
        console.log("contract stafiEther address: ", this.ContractStafiEther.address)
        await this.ContractStafiUpgrade.addContract("stafiEther", this.ContractStafiEther.address)


        this.ContractDepositContract = await this.FactoryDepositContract.deploy()
        await this.ContractDepositContract.deployed()
        console.log("contract depositContract address: ", this.ContractDepositContract.address)
        await this.ContractStafiUpgrade.addContract("ethDeposit", this.ContractDepositContract.address)


        this.ContractRETHToken = await this.FactoryRETHToken.deploy(this.ContractStafiStorage.address)
        await this.ContractRETHToken.deployed()
        console.log("contract RETHToken address: ", this.ContractRETHToken.address)
        await this.ContractStafiUpgrade.addContract("rETHToken", this.ContractRETHToken.address)


        this.ContractAddressSetStorage = await this.FactoryAddressSetStorage.deploy(this.ContractStafiStorage.address)
        await this.ContractAddressSetStorage.deployed()
        console.log("contract addressSetStorage address: ", this.ContractAddressSetStorage.address)
        await this.ContractStafiUpgrade.addContract("addressSetStorage", this.ContractAddressSetStorage.address)

        this.ContractPubkeySetStorage = await this.FactoryPubkeySetStorage.deploy(this.ContractStafiStorage.address)
        await this.ContractPubkeySetStorage.deployed()
        console.log("contract pubkeySetStorage address: ", this.ContractPubkeySetStorage.address)
        await this.ContractStafiUpgrade.addContract("pubkeySetStorage", this.ContractPubkeySetStorage.address)

        this.ContractAddressQueueStorage = await this.FactoryAddressQueueStorage.deploy(this.ContractStafiStorage.address)
        await this.ContractAddressQueueStorage.deployed()
        console.log("contract addressQueueStorage address: ", this.ContractAddressQueueStorage.address)
        await this.ContractStafiUpgrade.addContract("addressQueueStorage", this.ContractAddressQueueStorage.address)



        this.ContractStafiNetworkSettings = await this.FactoryStafiNetworkSettings.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiNetworkSettings.deployed()
        console.log("contract stafiNetworkSettings address: ", this.ContractStafiNetworkSettings.address)
        await this.ContractStafiUpgrade.addContract("stafiNetworkSettings", this.ContractStafiNetworkSettings.address)

        this.ContractStafiStakingPoolSettings = await this.FactoryStafiStakingPoolSettings.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiStakingPoolSettings.deployed()
        console.log("contract stafiStakingPoolSettings address: ", this.ContractStafiStakingPoolSettings.address)
        await await this.ContractStafiUpgrade.addContract("stafiStakingPoolSettings", this.ContractStafiStakingPoolSettings.address)


        this.ContractStafiStakingPoolQueue = await this.FactoryStafiStakingPoolQueue.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiStakingPoolQueue.deployed()
        console.log("contract stafiStakingPoolQueue address: ", this.ContractStafiStakingPoolQueue.address)
        await this.ContractStafiUpgrade.addContract("stafiStakingPoolQueue", this.ContractStafiStakingPoolQueue.address)

        this.ContractStafiStakingPoolManager = await this.FactoryStafiStakingPoolManager.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiStakingPoolManager.deployed()
        console.log("contract stafiStakingPoolManager address: ", this.ContractStafiStakingPoolManager.address)
        await this.ContractStafiUpgrade.addContract("stafiStakingPoolManager", this.ContractStafiStakingPoolManager.address)

        this.ContractStafiStakingPoolDelegate = await this.FactoryStafiStakingPoolDelegate.deploy()
        await this.ContractStafiStakingPoolDelegate.deployed()
        console.log("contract stafiStakingPoolDelegate address: ", this.ContractStafiStakingPoolDelegate.address)
        await this.ContractStafiUpgrade.addContract("stafiStakingPoolDelegate", this.ContractStafiStakingPoolDelegate.address)



        this.ContractStafiNodeManager = await this.FactoryStafiNodeManager.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiNodeManager.deployed()
        console.log("contract stafiNodeManager address: ", this.ContractStafiNodeManager.address)
        await this.ContractStafiUpgrade.addContract("stafiNodeManager", this.ContractStafiNodeManager.address)

        this.ContractStafiSuperNode = await this.FactoryStafiSuperNode.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiSuperNode.deployed()
        console.log("contract stafiSuperNode address: ", this.ContractStafiSuperNode.address)
        await this.ContractStafiUpgrade.addContract("stafiSuperNode", this.ContractStafiSuperNode.address)

        this.ContractStafiLightNode = await this.FactoryStafiLightNode.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiLightNode.deployed()
        console.log("contract stafiLightNode address: ", this.ContractStafiLightNode.address)
        await this.ContractStafiUpgrade.addContract("stafiLightNode", this.ContractStafiLightNode.address)


        this.ContractStafiNetworkBalances = await this.FactoryStafiNetworkBalances.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiNetworkBalances.deployed()
        console.log("contract stafiNetworkBalances address: ", this.ContractStafiNetworkBalances.address)
        await this.ContractStafiUpgrade.addContract("stafiNetworkBalances", this.ContractStafiNetworkBalances.address)

        this.ContractStafiNetworkWithdrawal = await this.FactoryStafiNetworkWithdrawal.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiNetworkWithdrawal.deployed()
        console.log("contract stafiNetworkWithdrawal address: ", this.ContractStafiNetworkWithdrawal.address)
        await this.ContractStafiUpgrade.addContract("stafiNetworkWithdrawal", this.ContractStafiNetworkWithdrawal.address)

        this.ContractStafiDistributor = await this.FactoryStafiDistributor.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiDistributor.deployed()
        console.log("contract stafi distributor address: ", this.ContractStafiDistributor.address)
        await this.ContractStafiUpgrade.addContract("stafiDistributor", this.ContractStafiDistributor.address)

        this.ContractStafiFeePool = await this.FactoryStafiFeePool.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiFeePool.deployed()
        console.log("contract stafi fee pool address: ", this.ContractStafiFeePool.address)
        await this.ContractStafiUpgrade.addContract("stafiFeePool", this.ContractStafiFeePool.address)

        this.ContractStafiSuperNodeFeePool = await this.FactoryStafiSuperNodeFeePool.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiSuperNodeFeePool.deployed()
        console.log("contract stafi super node fee pool address: ", this.ContractStafiSuperNodeFeePool.address)
        await this.ContractStafiUpgrade.addContract("stafiSuperNodeFeePool", this.ContractStafiSuperNodeFeePool.address)



        this.ContracStafiNodeDeposit = await this.FactoryStafiNodeDeposit.deploy(this.ContractStafiStorage.address)
        await this.ContracStafiNodeDeposit.deployed()
        console.log("contract stafiNodeDeposit address: ", this.ContracStafiNodeDeposit.address)
        await this.ContractStafiUpgrade.addContract("stafiNodeDeposit", this.ContracStafiNodeDeposit.address)

        this.ContractStafiUserDeposit = await this.FactoryStafiUserDeposit.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiUserDeposit.deployed()
        console.log("contract stafiUserDeposit address: ", this.ContractStafiUserDeposit.address)
        await this.ContractStafiUpgrade.addContract("stafiUserDeposit", this.ContractStafiUserDeposit.address)



        await this.ContractStafiUpgrade.initStorage(true)

        this.WithdrawalCredentials = '0x00d0d8e23e26afa86382b1f1e7b7af7b5d431bfa68d3b3f3c2fe2a6e54353fa8'
        await this.ContractStafiNetworkSettings.setWithdrawalCredentials(this.WithdrawalCredentials)

        await this.ContractStafiNodeManager.connect(this.AccountAdmin).setNodeTrusted(this.AccountTrustNode1.address, true)
        await this.ContractStafiNodeManager.connect(this.AccountAdmin).setNodeSuper(this.AccountSuperNode1.address, true)

    })

    it("node and user should deposit/stake success", async function () {
        console.log("latest block: ", await time.latestBlock())

        // user deposit
        let userDepositTx = await this.ContractStafiUserDeposit.connect(this.AccountUser1).deposit({ from: this.AccountUser1.address, value: web3.utils.toWei('28', 'ether') })
        let userDepositTxRecipient = await userDepositTx.wait()
        console.log("user deposit tx gas: ", userDepositTxRecipient.gasUsed.toString())

        // node deposit
        let depositData = {
            pubkey: beacon.getValidatorPubkey(),
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(4000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };
        let depositData2 = {
            pubkey: beacon.getValidatorPubkey(),
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(4000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };
        let depositDataRoot = beacon.getDepositDataRoot(depositData);
        let depositDataRoot2 = beacon.getDepositDataRoot(depositData2);

        let nodeDepositTx = await this.ContracStafiNodeDeposit.connect(this.AccountNode1).deposit(
            [depositData.pubkey, depositData2.pubkey], [depositData.signature, depositData2.signature], [depositDataRoot, depositDataRoot2], { from: this.AccountNode1.address, value: web3.utils.toWei('8', 'ether') })

        let nodeDepositTxRecipient = await nodeDepositTx.wait()
        console.log("node deposit tx gas: ", nodeDepositTxRecipient.gasUsed.toString())

        // check state
        let stakingPoolAddress = await this.ContractStafiStakingPoolManager.getStakingPoolByPubkey(depositData.pubkey)
        let contractStakingPool = await ethers.getContractAt("StafiStakingPoolDelegate", stakingPoolAddress)

        let stakingPoolAddress2 = await this.ContractStafiStakingPoolManager.getStakingPoolByPubkey(depositData2.pubkey)
        let contractStakingPool2 = await ethers.getContractAt("StafiStakingPoolDelegate", stakingPoolAddress2)

        expect(await contractStakingPool.getStatus()).to.equal(1)
        expect(await contractStakingPool.getNodeDepositAssigned()).to.equal(true)
        expect(await contractStakingPool.getUserDepositAssigned()).to.equal(true)
        expect(await contractStakingPool.getWithdrawalCredentialsMatch()).to.equal(false)
        expect((await contractStakingPool.getNodeDepositBalance()).toString()).to.equal(web3.utils.toWei("4", 'ether'))
        expect((await contractStakingPool.getUserDepositBalance()).toString()).to.equal(web3.utils.toWei("28", 'ether'))
        expect((await ethers.provider.getBalance(stakingPoolAddress)).toString()).to.equal(web3.utils.toWei("28", 'ether'))

        expect(await contractStakingPool2.getStatus()).to.equal(0)
        expect(await contractStakingPool2.getNodeDepositAssigned()).to.equal(true)
        expect(await contractStakingPool2.getUserDepositAssigned()).to.equal(false)
        expect(await contractStakingPool2.getWithdrawalCredentialsMatch()).to.equal(false)
        expect((await contractStakingPool2.getNodeDepositBalance()).toString()).to.equal(web3.utils.toWei("4", 'ether'))
        expect((await contractStakingPool2.getUserDepositBalance()).toString()).to.equal(web3.utils.toWei("0", 'ether'))
        expect((await ethers.provider.getBalance(stakingPoolAddress2)).toString()).to.equal(web3.utils.toWei("0", 'ether'))

        expect((await ethers.provider.getBalance(this.ContractDepositContract.address)).toString()).to.equal(web3.utils.toWei("8", 'ether'))

        // trust node vote withdrawCredentials
        await contractStakingPool.connect(this.AccountTrustNode1).voteWithdrawCredentials()
        await contractStakingPool2.connect(this.AccountTrustNode1).voteWithdrawCredentials()

        expect(await contractStakingPool.getWithdrawalCredentialsMatch()).to.equal(true)
        expect(await contractStakingPool.getWithdrawalCredentialsMatch()).to.equal(true)

        // user deposit
        let userDepositTx2 = await this.ContractStafiUserDeposit.connect(this.AccountUser1).deposit({ from: this.AccountUser1.address, value: web3.utils.toWei('28', 'ether') })
        let userDepositTxRecipient2 = await userDepositTx2.wait()
        console.log("user deposit tx2 gas: ", userDepositTxRecipient2.gasUsed.toString())

        expect((await contractStakingPool2.getUserDepositBalance()).toString()).to.equal(web3.utils.toWei("28", 'ether'))
        expect((await ethers.provider.getBalance(stakingPoolAddress2)).toString()).to.equal(web3.utils.toWei("28", 'ether'))
        expect(await contractStakingPool2.getStatus()).to.equal(1)

        // node stake
        let depositDataInStake = {
            pubkey: depositData.pubkey,
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(28000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };
        let depositDataRootInStake = beacon.getDepositDataRoot(depositDataInStake);
        let depositDataInStake2 = {
            pubkey: depositData2.pubkey,
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(28000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };
        let depositDataRootInStake2 = beacon.getDepositDataRoot(depositDataInStake2);

        let nodeStakeTx = await this.ContracStafiNodeDeposit.connect(this.AccountNode1).stake(
            [stakingPoolAddress, stakingPoolAddress2], [depositDataInStake.signature, depositDataInStake2.signature], [depositDataRootInStake, depositDataRootInStake2])
        let nodeStakeTxRecipient = await nodeStakeTx.wait()
        console.log("node stake tx gas: ", nodeStakeTxRecipient.gasUsed.toString())

        // check state
        expect((await ethers.provider.getBalance(stakingPoolAddress)).toString()).to.equal(web3.utils.toWei("0", 'ether'))
        expect(await contractStakingPool.getStatus()).to.equal(2)
        expect(await contractStakingPool.getStatus()).to.equal(2)

        expect((await ethers.provider.getBalance(stakingPoolAddress2)).toString()).to.equal(web3.utils.toWei("0", 'ether'))
        expect(await contractStakingPool2.getStatus()).to.equal(2)

        expect((await ethers.provider.getBalance(this.ContractDepositContract.address)).toString()).to.equal(web3.utils.toWei("64", 'ether'))

        expect((await this.ContractStafiStakingPoolManager.getNodeStakingPoolCount(this.AccountNode1.address)).toString()).to.equal("2")
        expect((await this.ContractStafiStakingPoolManager.getNodeStakingPoolAt(this.AccountNode1.address, 0))).to.equal(stakingPoolAddress)
        expect((await this.ContractStafiStakingPoolManager.getNodeStakingPoolAt(this.AccountNode1.address, 1))).to.equal(stakingPoolAddress2)
    })


    it("super node should deposit/stake success", async function () {
        console.log("latest block: ", await time.latestBlock())
        // enable deposit
        await this.ContractStafiSuperNode.connect(this.AccountAdmin).setSuperNodeDepositEnabled(true)
        // user deposit
        let userDepositTx = await this.ContractStafiUserDeposit.connect(this.AccountUser1).deposit({ from: this.AccountUser1.address, value: web3.utils.toWei('68', 'ether') })
        let userDepositTxRecipient = await userDepositTx.wait()
        console.log("user deposit tx gas: ", userDepositTxRecipient.gasUsed.toString())

        expect((await ethers.provider.getBalance(this.ContractStafiEther.address)).toString()).to.equal(web3.utils.toWei("68", 'ether'))
        expect((await this.ContractStafiEther.balanceOf(this.ContractStafiUserDeposit.address)).toString()).to.equal(web3.utils.toWei("68", "ether"));
        expect((await this.ContractRETHToken.balanceOf(this.AccountUser1.address)).toString()).to.equal(web3.utils.toWei("68", "ether"));

        // node deposit
        let depositDataInDeposit = {
            pubkey: beacon.getValidatorPubkey(),
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(1000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };

        let depositDataInDeposit2 = {
            pubkey: beacon.getValidatorPubkey(),
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(1000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };
        let depositDataInDepositRoot = beacon.getDepositDataRoot(depositDataInDeposit);
        let depositDataInDepositRoot2 = beacon.getDepositDataRoot(depositDataInDeposit2);

        let nodeDepositTx = await this.ContractStafiSuperNode.connect(this.AccountSuperNode1).deposit(
            [depositDataInDeposit.pubkey, depositDataInDeposit2.pubkey], [depositDataInDeposit.signature, depositDataInDeposit2.signature], [depositDataInDepositRoot, depositDataInDepositRoot2])
        let nodeDepositTxRecipient = await nodeDepositTx.wait()
        console.log("super node deposit tx gas: ", nodeDepositTxRecipient.gasUsed.toString())

        // trust node vote withdrawCredentials
        await this.ContractStafiSuperNode.connect(this.AccountTrustNode1).voteWithdrawCredentials(depositDataInDeposit.pubkey, true)
        await this.ContractStafiSuperNode.connect(this.AccountTrustNode1).voteWithdrawCredentials(depositDataInDeposit2.pubkey, true)

        expect((await this.ContractStafiSuperNode.getSuperNodePubkeyStatus(depositDataInDeposit.pubkey)).toString()).to.equal("2")
        expect((await this.ContractStafiSuperNode.getSuperNodePubkeyStatus(depositDataInDeposit2.pubkey)).toString()).to.equal("2")

        // node stake
        let depositDataInStake = {
            pubkey: depositDataInDeposit.pubkey,
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(31000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };

        let depositDataInStake2 = {
            pubkey: depositDataInDeposit2.pubkey,
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(31000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };
        let depositDataInStakeRoot = beacon.getDepositDataRoot(depositDataInStake);
        let depositDataInStakeRoot2 = beacon.getDepositDataRoot(depositDataInStake2);

        let nodeStakeTx = await this.ContractStafiSuperNode.connect(this.AccountSuperNode1).stake(
            [depositDataInStake.pubkey, depositDataInStake2.pubkey], [depositDataInStake.signature, depositDataInStake2.signature], [depositDataInStakeRoot, depositDataInStakeRoot2])
        let nodeStakeTxRecipient = await nodeStakeTx.wait()
        console.log("super node stake tx gas: ", nodeStakeTxRecipient.gasUsed.toString())

        expect((await ethers.provider.getBalance(this.ContractStafiEther.address)).toString()).to.equal(web3.utils.toWei("4", 'ether'))
        expect((await this.ContractStafiEther.balanceOf(this.ContractStafiUserDeposit.address)).toString()).to.equal(web3.utils.toWei("4", "ether"));
        expect((await ethers.provider.getBalance(this.ContractDepositContract.address)).toString()).to.equal(web3.utils.toWei("64", 'ether'))

        expect((await this.ContractStafiSuperNode.getSuperNodePubkeyCount(this.AccountSuperNode1.address)).toString()).to.equal("2")
        expect((await this.ContractStafiSuperNode.getSuperNodePubkeyAt(this.AccountSuperNode1.address, 0))).to.equal("0x" + depositDataInStake.pubkey.toString("hex"))
        expect((await this.ContractStafiSuperNode.getSuperNodePubkeyAt(this.AccountSuperNode1.address, 1))).to.equal("0x" + depositDataInStake2.pubkey.toString("hex"))

    })

    it("light node should deposit/stake success", async function () {
        console.log("latest block: ", await time.latestBlock())
        // enable deposit
        await this.ContractStafiLightNode.connect(this.AccountAdmin).setLightNodeDepositEnabled(true)
        // user deposit
        let userDepositTx = await this.ContractStafiUserDeposit.connect(this.AccountUser1).deposit({ from: this.AccountUser1.address, value: web3.utils.toWei('68', 'ether') })
        let userDepositTxRecipient = await userDepositTx.wait()
        console.log("user deposit tx gas: ", userDepositTxRecipient.gasUsed.toString())

        expect((await ethers.provider.getBalance(this.ContractStafiEther.address)).toString()).to.equal(web3.utils.toWei("68", 'ether'))
        expect((await this.ContractStafiEther.balanceOf(this.ContractStafiUserDeposit.address)).toString()).to.equal(web3.utils.toWei("68", "ether"));
        expect((await this.ContractRETHToken.balanceOf(this.AccountUser1.address)).toString()).to.equal(web3.utils.toWei("68", "ether"));

        // node deposit
        let depositDataInDeposit = {
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
        let depositDataInDepositRoot = beacon.getDepositDataRoot(depositDataInDeposit);
        let depositDataInDepositRoot2 = beacon.getDepositDataRoot(depositDataInDeposit2);

        let nodeDepositTx = await this.ContractStafiLightNode.connect(this.AccountUser2).deposit(
            [depositDataInDeposit.pubkey, depositDataInDeposit2.pubkey], [depositDataInDeposit.signature, depositDataInDeposit2.signature], [depositDataInDepositRoot, depositDataInDepositRoot2],
            { from: this.AccountUser2.address, value: web3.utils.toWei('8', 'ether') })
        let nodeDepositTxRecipient = await nodeDepositTx.wait()
        console.log("light node deposit tx gas: ", nodeDepositTxRecipient.gasUsed.toString())

        // trust node vote withdrawCredentials
        await this.ContractStafiLightNode.connect(this.AccountTrustNode1).voteWithdrawCredentials(depositDataInDeposit.pubkey, true)
        await this.ContractStafiLightNode.connect(this.AccountTrustNode1).voteWithdrawCredentials(depositDataInDeposit2.pubkey, true)

        expect((await this.ContractStafiLightNode.getLightNodePubkeyStatus(depositDataInDeposit.pubkey)).toString()).to.equal("2")
        expect((await this.ContractStafiLightNode.getLightNodePubkeyStatus(depositDataInDeposit2.pubkey)).toString()).to.equal("2")

        // node stake
        let depositDataInStake = {
            pubkey: depositDataInDeposit.pubkey,
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
        let depositDataInStakeRoot = beacon.getDepositDataRoot(depositDataInStake);
        let depositDataInStakeRoot2 = beacon.getDepositDataRoot(depositDataInStake2);

        let nodeStakeTx = await this.ContractStafiLightNode.connect(this.AccountUser2).stake(
            [depositDataInStake.pubkey, depositDataInStake2.pubkey], [depositDataInStake.signature, depositDataInStake2.signature], [depositDataInStakeRoot, depositDataInStakeRoot2])
        let nodeStakeTxRecipient = await nodeStakeTx.wait()
        console.log("light node stake tx gas: ", nodeStakeTxRecipient.gasUsed.toString())

        expect((await this.ContractStafiLightNode.getLightNodePubkeyStatus(depositDataInDeposit.pubkey)).toString()).to.equal("3")
        expect((await this.ContractStafiLightNode.getLightNodePubkeyStatus(depositDataInDeposit2.pubkey)).toString()).to.equal("3")
        expect((await ethers.provider.getBalance(this.ContractStafiEther.address)).toString()).to.equal(web3.utils.toWei("12", 'ether'))
        expect((await this.ContractStafiEther.balanceOf(this.ContractStafiUserDeposit.address)).toString()).to.equal(web3.utils.toWei("12", "ether"));
        expect((await ethers.provider.getBalance(this.ContractDepositContract.address)).toString()).to.equal(web3.utils.toWei("64", 'ether'))

        expect((await this.ContractStafiLightNode.getLightNodePubkeyCount(this.AccountUser2.address)).toString()).to.equal("2")
        expect((await this.ContractStafiLightNode.getLightNodePubkeyAt(this.AccountUser2.address, 0))).to.equal("0x" + depositDataInStake.pubkey.toString("hex"))
        expect((await this.ContractStafiLightNode.getLightNodePubkeyAt(this.AccountUser2.address, 1))).to.equal("0x" + depositDataInStake2.pubkey.toString("hex"))

        // node deposit3
        let depositDataInDeposit3 = {
            pubkey: beacon.getValidatorPubkey(),
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(4000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };
        let depositDataInDepositRoot3 = beacon.getDepositDataRoot(depositDataInDeposit3);

        let nodeDepositTx3 = await this.ContractStafiLightNode.connect(this.AccountUser2).deposit(
            [depositDataInDeposit3.pubkey], [depositDataInDeposit3.signature], [depositDataInDepositRoot3],
            { from: this.AccountUser2.address, value: web3.utils.toWei('4', 'ether') })
        let nodeDepositTxRecipient3 = await nodeDepositTx3.wait()
        console.log("light node deposit tx3 gas: ", nodeDepositTxRecipient3.gasUsed.toString())
        // trust node vote withdrawCredentials
        await this.ContractStafiLightNode.connect(this.AccountTrustNode1).voteWithdrawCredentials(depositDataInDeposit3.pubkey, true)

        await this.ContractStafiLightNode.connect(this.AccountUser2).offBoard(depositDataInDeposit3.pubkey, { from: this.AccountUser2.address })
        await this.ContractStafiLightNode.connect(this.AccountUser1).provideNodeDepositToken(depositDataInDeposit3.pubkey, { from: this.AccountUser1.address, value: web3.utils.toWei('4', 'ether') });

        expect((await this.ContractStafiEther.balanceOf(this.ContractStafiLightNode.address)).toString()).to.equal(web3.utils.toWei("4", "ether"));

        await this.ContractStafiLightNode.connect(this.AccountUser2).withdrawNodeDepositToken(depositDataInDeposit3.pubkey, { from: this.AccountUser2.address })
        expect((await this.ContractStafiLightNode.getLightNodePubkeyStatus(depositDataInDeposit3.pubkey)).toString()).to.equal("7")
        expect((await this.ContractStafiEther.balanceOf(this.ContractStafiLightNode.address)).toString()).to.equal(web3.utils.toWei("0", "ether"));
        expect((await this.ContractStafiLightNode.getLightNodePubkeyCount(this.AccountUser2.address)).toString()).to.equal("3")
        expect((await this.ContractStafiLightNode.getLightNodePubkeyAt(this.AccountUser2.address, 2))).to.equal("0x" + depositDataInDeposit3.pubkey.toString("hex"))
    })

    it("stafi distributor should distribute fee/super node fee success", async function () {
        console.log("latest block: ", await time.latestBlock())
        await this.AccountUser1.sendTransaction({
            to: this.ContractStafiFeePool.address,
            value: web3.utils.toWei("38", "ether")
        })

        await this.AccountUser1.sendTransaction({
            to: this.ContractStafiSuperNodeFeePool.address,
            value: web3.utils.toWei("3", "ether")
        })
        // distribute fee
        let distributeFeeTx = await this.ContractStafiDistributor.connect(this.AccountUser2).distributeFee(web3.utils.toWei("35", "ether"), { from: this.AccountUser2.address })
        let distributeTxRecipient = await distributeFeeTx.wait()
        console.log("distribute fee tx gas: ", distributeTxRecipient.gasUsed.toString())

        // users: (35-35*1/10)*7/8*9/10 = 24.80625
        // node+platform:  10.19375
        expect((await this.ContractStafiEther.balanceOf(this.ContractStafiUserDeposit.address)).toString()).to.equal(web3.utils.toWei("24.80625", "ether"));
        expect((await this.ContractStafiEther.balanceOf(this.ContractStafiDistributor.address)).toString()).to.equal(web3.utils.toWei("10.19375", "ether"));
        expect((await ethers.provider.getBalance(this.ContractStafiFeePool.address)).toString()).to.equal(web3.utils.toWei("3", "ether"));

        // distribute fee
        let distributeSuperNodeFeeTx = await this.ContractStafiDistributor.connect(this.AccountUser2).distributeSuperNodeFee(web3.utils.toWei("3", "ether"), { from: this.AccountUser2.address })
        let distributeSuperNodeFeeTxRecipient = await distributeSuperNodeFeeTx.wait()
        console.log("distribute super node fee tx gas: ", distributeSuperNodeFeeTxRecipient.gasUsed.toString())

        // users: (3-3*1/10)*9/10 = 2.43
        // node+platform: 0.57
        expect((await this.ContractStafiEther.balanceOf(this.ContractStafiUserDeposit.address)).toString()).to.equal(web3.utils.toWei("27.23625", "ether"));
        expect((await this.ContractStafiEther.balanceOf(this.ContractStafiDistributor.address)).toString()).to.equal(web3.utils.toWei("10.76375", "ether"));
        expect((await ethers.provider.getBalance(this.ContractStafiSuperNodeFeePool.address)).toString()).to.equal(web3.utils.toWei("0", "ether"));

        let tree = new balance_tree_1.default([
            { account: this.AccountNode1.address, amount: web3.utils.toWei("1", "ether") },
            { account: this.AccountNode2.address, amount: web3.utils.toWei("2", "ether") },
            { account: this.AccountNode2.address, amount: web3.utils.toWei("3", "ether") },
            { account: this.AccountNode2.address, amount: web3.utils.toWei("4", "ether") },
        ]);

        console.log("root: ", tree.getHexRoot());

        // set merkle root
        let setMerkleRootTx = await this.ContractStafiDistributor.connect(this.AccountAdmin).setMerkleRoot(0, tree.getHexRoot(), { from: this.AccountAdmin.address })
        let setMerkleRootTxRecepient = await setMerkleRootTx.wait()
        console.log("setMerkleRoot  tx gas: ", setMerkleRootTxRecepient.gasUsed.toString())

        let proof = tree.getProof(0, this.AccountNode1.address, web3.utils.toWei("1", "ether"))
        let proof2 = tree.getProof(1, this.AccountNode2.address, web3.utils.toWei("2", "ether"))

        expect((await this.ContractStafiDistributor.isClaimed(0, 0))).to.equal(false);
        expect((await this.ContractStafiDistributor.isClaimed(0, 1))).to.equal(false);
        let node1Balance = await ethers.provider.getBalance(this.AccountNode1.address)
        let node2Balance = await ethers.provider.getBalance(this.AccountNode2.address)

        // claim
        let claimTx = await this.ContractStafiDistributor.connect(this.AccountUser1).claim([0, 0], [0, 1], [this.AccountNode1.address, this.AccountNode2.address],
            [web3.utils.toWei("1", "ether"), web3.utils.toWei("2", "ether")], [proof, proof2], { from: this.AccountUser1.address })
        let claimTxRecepient = await claimTx.wait()
        console.log("claim tx gas: ", claimTxRecepient.gasUsed.toString())

        expect((await this.ContractStafiEther.balanceOf(this.ContractStafiDistributor.address)).toString()).to.equal(web3.utils.toWei("7.76375", "ether"));
        expect((await ethers.provider.getBalance(this.AccountNode1.address)).sub(node1Balance).toString()).to.equal(web3.utils.toWei("1", "ether"));
        expect((await ethers.provider.getBalance(this.AccountNode2.address)).sub(node2Balance).toString()).to.equal(web3.utils.toWei("2", "ether"));

        expect((await this.ContractStafiDistributor.isClaimed(0, 0))).to.equal(true);
        expect((await this.ContractStafiDistributor.isClaimed(0, 1))).to.equal(true);
        expect((await this.ContractStafiDistributor.isClaimed(0, 2))).to.equal(false);
    })

})