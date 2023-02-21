var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
const { ethers, web3 } = require("hardhat")
const { expect } = require("chai")
const { time, beacon } = require("./utilities")
var balance_tree_1 = __importDefault(require("./src/balance-tree"));

describe("upgrade to v2 test", function () {
    before(async function () {
        this.signers = await ethers.getSigners()

        this.AccountUser1 = this.signers[1]
        this.AccountNode1 = this.signers[2]
        this.AccountTrustNode1 = this.signers[3]
        this.AccountWithdrawer1 = this.signers[4]
        this.AccountUser2 = this.signers[5]
        this.AccountSuperNode1 = this.signers[6]
        this.AccountNode2 = this.signers[7]
        this.AccountNode3 = this.signers[8]


        // state on mainnet
        this.Admin = await ethers.getImpersonatedSigner("0x211bed4bd65d4c01643377d95491b8c4b533eaad");
        console.log("admin: ", this.Admin.address);
        await this.AccountUser1.sendTransaction({
            to: this.Admin.address,
            value: web3.utils.toWei("30", "ether")
        })

        this.TrustNode1 = await ethers.getImpersonatedSigner("0xEBf7e97D801d9EDD5A4027919Db55aA12681aEfe");
        console.log("trust node1 : ", this.TrustNode1.address);
        await this.AccountUser1.sendTransaction({
            to: this.TrustNode1.address,
            value: web3.utils.toWei("30", "ether")
        })
        this.TrustNode2 = await ethers.getImpersonatedSigner("0x80AA112eED03dCC44bEE7F2A1dA7e5A0d04591BD");
        console.log("trust node1 : ", this.TrustNode2.address);
        await this.AccountUser1.sendTransaction({
            to: this.TrustNode2.address,
            value: web3.utils.toWei("30", "ether")
        })


        this.StafiStorageAddress = "0x6c2f7b6110a37b3b0fbdd811876be368df02e8b0"
        this.StafiUpgradeAddress = "0xb0da556df7c66ed429191e113974a6c474f2b389"
        this.REthTokenAddress = "0x9559aaa82d9649c7a7b220e7c461d2e74c9a3593"
        this.StafiNetworkSettingsAddress = "0x1a5474e63519bf47860856f03f414445382dc3f1"
        this.DepositContractAddress = "0x00000000219ab540356cbb839cbe05303d7705fa"
        this.StafiEtherAddress = "0x54896f542f044709807f0d79033934d661d39fc1"


        this.ContractStafiStorage = await ethers.getContractAt("IStafiStorage", this.StafiStorageAddress)
        this.ContractStafiUpgrade = await ethers.getContractAt("IStafiUpgrade", this.StafiUpgradeAddress)
        this.ContractRETHToken = await ethers.getContractAt("RETHToken", this.REthTokenAddress)
        this.ContractStafiNetworkSettings = await ethers.getContractAt("StafiNetworkSettings", this.StafiNetworkSettingsAddress)
        this.ContractDepositContract = await ethers.getContractAt("DepositContract", this.DepositContractAddress)
        this.ContractStafiEther = await ethers.getContractAt("StafiEther", this.StafiEtherAddress)


        this.WithdrawalCredentials = await this.ContractStafiNetworkSettings.getWithdrawalCredentials()
        console.log("withdrawalCredentials: ", this.WithdrawalCredentials)
        this.NodeConsensusThreshold = await this.ContractStafiNetworkSettings.getNodeConsensusThreshold()
        console.log("NodeConsensusThreshold: ", this.NodeConsensusThreshold.toString())


        console.log("contract.storage.initialised: ", (await this.ContractStafiStorage.getBool(web3.utils.soliditySha3("contract.storage.initialised"))).toString())
        console.log("burn enabled: ", await this.ContractRETHToken.getBurnEnabled())


        // upgrade contracts
        this.FactoryStafiNodeDeposit = await ethers.getContractFactory("StafiNodeDeposit", this.Admin)
        this.ContracStafiNodeDeposit = await this.FactoryStafiNodeDeposit.deploy(this.StafiStorageAddress)
        await this.ContracStafiNodeDeposit.deployed()
        console.log("contract stafiNodeDeposit address: ", this.ContracStafiNodeDeposit.address)
        await this.ContractStafiUpgrade.connect(this.Admin).upgradeContract("stafiNodeDeposit", this.ContracStafiNodeDeposit.address)


        this.FactoryStafiUserDeposit = await ethers.getContractFactory("StafiUserDeposit", this.Admin)
        this.ContractStafiUserDeposit = await this.FactoryStafiUserDeposit.deploy(this.StafiStorageAddress)
        await this.ContractStafiUserDeposit.deployed()
        console.log("contract stafiUserDeposit address: ", this.ContractStafiUserDeposit.address)
        await this.ContractStafiUpgrade.connect(this.Admin).upgradeContract("stafiUserDeposit", this.ContractStafiUserDeposit.address)


        // this.FactoryStafiStakingPoolManager = await ethers.getContractFactory("StafiStakingPoolManager", this.admin)
        // this.ContractStafiStakingPoolManager = await this.FactoryStafiStakingPoolManager.deploy(this.ContractStafiStorage.address)
        // await this.ContractStafiStakingPoolManager.deployed()
        // console.log("contract stafiStakingPoolManager address: ", this.ContractStafiStakingPoolManager.address)
        // await this.ContractStafiUpgrade.connect(this.Admin).upgradeContract("stafiStakingPoolManager", this.ContractStafiStakingPoolManager.address)

        this.FactoryStafiNodeManager = await ethers.getContractFactory("StafiNodeManager", this.Admin)
        this.ContractStafiNodeManager = await this.FactoryStafiNodeManager.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiNodeManager.deployed()
        console.log("contract stafiNodeManager address: ", this.ContractStafiNodeManager.address)
        await this.ContractStafiUpgrade.connect(this.Admin).upgradeContract("stafiNodeManager", this.ContractStafiNodeManager.address)

        this.FactoryStafiNetworkSettings = await ethers.getContractFactory("StafiNetworkSettings", this.Admin)
        this.ContractStafiNetworkSettings = await this.FactoryStafiNetworkSettings.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiNetworkSettings.deployed()
        console.log("contract stafiNetworkSettings address: ", this.ContractStafiNetworkSettings.address)
        await this.ContractStafiUpgrade.connect(this.Admin).upgradeContract("stafiNetworkSettings", this.ContractStafiNetworkSettings.address)

        // deploy new contracts
        // this.FactoryStafiStakingPoolDelegate = await ethers.getContractFactory("StafiStakingPoolDelegate", this.Admin)
        // this.ContractStafiStakingPoolDelegate = await this.FactoryStafiStakingPoolDelegate.deploy()
        // await this.ContractStafiStakingPoolDelegate.deployed()
        // console.log("contract stafiStakingPoolDelegate address: ", this.ContractStafiStakingPoolDelegate.address)
        // await this.ContractStafiUpgrade.connect(this.Admin).addContract("stafiStakingPoolDelegate", this.ContractStafiStakingPoolDelegate.address)

        this.FactoryStafiDistributor = await ethers.getContractFactory("StafiDistributor", this.Admin)
        this.ContractStafiDistributor = await this.FactoryStafiDistributor.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiDistributor.deployed()
        console.log("contract stafi distributor address: ", this.ContractStafiDistributor.address)
        await this.ContractStafiUpgrade.connect(this.Admin).addContract("stafiDistributor", this.ContractStafiDistributor.address)

        this.FactoryStafiFeePool = await ethers.getContractFactory("StafiFeePool", this.Admin)
        this.ContractStafiFeePool = await this.FactoryStafiFeePool.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiFeePool.deployed()
        console.log("contract stafi fee pool address: ", this.ContractStafiFeePool.address)
        await this.ContractStafiUpgrade.connect(this.Admin).addContract("stafiFeePool", this.ContractStafiFeePool.address)

        this.FactoryStafiSuperNodeFeePool = await ethers.getContractFactory("StafiSuperNodeFeePool", this.Admin)
        this.ContractStafiSuperNodeFeePool = await this.FactoryStafiSuperNodeFeePool.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiSuperNodeFeePool.deployed()
        console.log("contract stafi super node fee pool address: ", this.ContractStafiSuperNodeFeePool.address)
        await this.ContractStafiUpgrade.connect(this.Admin).addContract("stafiSuperNodeFeePool", this.ContractStafiSuperNodeFeePool.address)

        this.FactoryStafiSuperNode = await ethers.getContractFactory("StafiSuperNode", this.Admin)
        this.ContractStafiSuperNode = await this.FactoryStafiSuperNode.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiSuperNode.deployed()
        console.log("contract stafiSuperNode address: ", this.ContractStafiSuperNode.address)
        await this.ContractStafiUpgrade.connect(this.Admin).addContract("stafiSuperNode", this.ContractStafiSuperNode.address)

        this.FactoryPubkeySetStorage = await ethers.getContractFactory("PubkeySetStorage", this.Admin)
        this.ContractPubkeySetStorage = await this.FactoryPubkeySetStorage.deploy(this.ContractStafiStorage.address)
        await this.ContractPubkeySetStorage.deployed()
        console.log("contract pubkeySetStorage address: ", this.ContractPubkeySetStorage.address)
        await this.ContractStafiUpgrade.connect(this.Admin).addContract("pubkeySetStorage", this.ContractPubkeySetStorage.address)


        // modify settings 
        await this.ContracStafiNodeDeposit.connect(this.Admin).setDepositEnabled(true)

        // add super node
        await this.ContractStafiNodeManager.connect(this.Admin).setNodeSuper(this.AccountSuperNode1.address, true)
        // set supernode pubkey limit
        await this.ContractStafiNetworkSettings.connect(this.Admin).setSuperNodePubkeyLimit(50)

        // state after upgrade
        console.log("trustedNode count", (await this.ContractStafiNodeManager.getTrustedNodeCount()).toString())
        console.log("trustedNode: ", (await this.ContractStafiNodeManager.getTrustedNodeAt(0)).toString())
        console.log("trustedNode: ", (await this.ContractStafiNodeManager.getTrustedNodeAt(1)).toString())
        console.log("trustedNode: ", (await this.ContractStafiNodeManager.getTrustedNodeAt(2)).toString())
        console.log("trustedNode: ", (await this.ContractStafiNodeManager.getTrustedNodeAt(3)).toString())
    })



    // it("node and user should deposit/stake success", async function () {
    //     console.log("latest block: ", await time.latestBlock())
    //     console.log("depositContract balance: ", (await ethers.provider.getBalance(this.ContractDepositContract.address)).toString())
    //     console.log("stafiEther balance: ", (await ethers.provider.getBalance(this.ContractStafiEther.address)).toString())
    //     // user deposit
    //     let userDepositTx = await this.ContractStafiUserDeposit.connect(this.AccountUser1).deposit({ from: this.AccountUser1.address, value: web3.utils.toWei('28', 'ether') })
    //     let userDepositTxRecipient = await userDepositTx.wait()
    //     console.log("user deposit tx gas: ", userDepositTxRecipient.gasUsed.toString())

    //     // node deposit
    //     let depositData = {
    //         pubkey: beacon.getValidatorPubkey(),
    //         withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
    //         amount: BigInt(4000000000), // gwei
    //         signature: beacon.getValidatorSignature(),
    //     };
    //     let depositData2 = {
    //         pubkey: beacon.getValidatorPubkey(),
    //         withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
    //         amount: BigInt(4000000000), // gwei
    //         signature: beacon.getValidatorSignature(),
    //     };
    //     let depositDataRoot = beacon.getDepositDataRoot(depositData);
    //     let depositDataRoot2 = beacon.getDepositDataRoot(depositData2);

    //     let nodeDepositTx = await this.ContracStafiNodeDeposit.connect(this.AccountNode1).deposit(
    //         [depositData.pubkey, depositData2.pubkey], [depositData.signature, depositData2.signature], [depositDataRoot, depositDataRoot2], { from: this.AccountNode1.address, value: web3.utils.toWei('8', 'ether') })

    //     let nodeDepositTxRecipient = await nodeDepositTx.wait()
    //     console.log("node deposit tx gas: ", nodeDepositTxRecipient.gasUsed.toString())

    //     // check state
    //     let stakingPoolAddress = await this.ContractStafiStakingPoolManager.getStakingPoolByPubkey(depositData.pubkey)
    //     let contractStakingPool = await ethers.getContractAt("StafiStakingPoolDelegate", stakingPoolAddress)

    //     let stakingPoolAddress2 = await this.ContractStafiStakingPoolManager.getStakingPoolByPubkey(depositData2.pubkey)
    //     let contractStakingPool2 = await ethers.getContractAt("StafiStakingPoolDelegate", stakingPoolAddress2)

    //     expect(await contractStakingPool.getStatus()).to.equal(1)
    //     expect(await contractStakingPool.getNodeDepositAssigned()).to.equal(true)
    //     expect(await contractStakingPool.getUserDepositAssigned()).to.equal(true)
    //     expect(await contractStakingPool.getWithdrawalCredentialsMatch()).to.equal(false)
    //     expect((await contractStakingPool.getNodeDepositBalance()).toString()).to.equal(web3.utils.toWei("4", 'ether'))
    //     expect((await contractStakingPool.getUserDepositBalance()).toString()).to.equal(web3.utils.toWei("28", 'ether'))
    //     expect((await ethers.provider.getBalance(stakingPoolAddress)).toString()).to.equal(web3.utils.toWei("28", 'ether'))

    //     expect(await contractStakingPool2.getStatus()).to.equal(1)
    //     expect(await contractStakingPool2.getNodeDepositAssigned()).to.equal(true)
    //     expect(await contractStakingPool2.getUserDepositAssigned()).to.equal(true)
    //     expect(await contractStakingPool2.getWithdrawalCredentialsMatch()).to.equal(false)
    //     expect((await contractStakingPool2.getNodeDepositBalance()).toString()).to.equal(web3.utils.toWei("4", 'ether'))
    //     expect((await contractStakingPool2.getUserDepositBalance()).toString()).to.equal(web3.utils.toWei("28", 'ether'))
    //     expect((await ethers.provider.getBalance(stakingPoolAddress2)).toString()).to.equal(web3.utils.toWei("28", 'ether'))

    //     expect((await ethers.provider.getBalance(this.ContractDepositContract.address)).toString()).to.equal("13391231000069000000000069")

    //     // trust node vote withdrawCredentials
    //     let voteWithdrawCredentials = await contractStakingPool.connect(this.TrustNode1).voteWithdrawCredentials()
    //     await contractStakingPool2.connect(this.TrustNode1).voteWithdrawCredentials()
    //     let voteWithdrawCredentialsRecipient = await voteWithdrawCredentials.wait()
    //     console.log("voteWithdrawCredentialsRecipient tx gas: ", voteWithdrawCredentialsRecipient.gasUsed.toString())

    //     expect(await contractStakingPool.getWithdrawalCredentialsMatch()).to.equal(true)
    //     expect(await contractStakingPool.getWithdrawalCredentialsMatch()).to.equal(true)

    //     // user deposit
    //     let userDepositTx2 = await this.ContractStafiUserDeposit.connect(this.AccountUser1).deposit({ from: this.AccountUser1.address, value: web3.utils.toWei('28', 'ether') })
    //     let userDepositTxRecipient2 = await userDepositTx2.wait()
    //     console.log("user deposit tx2 gas: ", userDepositTxRecipient2.gasUsed.toString())

    //     expect((await contractStakingPool2.getUserDepositBalance()).toString()).to.equal(web3.utils.toWei("28", 'ether'))
    //     expect((await ethers.provider.getBalance(stakingPoolAddress2)).toString()).to.equal(web3.utils.toWei("28", 'ether'))
    //     expect(await contractStakingPool2.getStatus()).to.equal(1)

    //     // node stake
    //     let depositDataInStake = {
    //         pubkey: depositData.pubkey,
    //         withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
    //         amount: BigInt(28000000000), // gwei
    //         signature: beacon.getValidatorSignature(),
    //     };
    //     let depositDataRootInStake = beacon.getDepositDataRoot(depositDataInStake);
    //     let depositDataInStake2 = {
    //         pubkey: depositData2.pubkey,
    //         withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
    //         amount: BigInt(28000000000), // gwei
    //         signature: beacon.getValidatorSignature(),
    //     };
    //     let depositDataRootInStake2 = beacon.getDepositDataRoot(depositDataInStake2);

    //     let nodeStakeTx = await this.ContracStafiNodeDeposit.connect(this.AccountNode1).stake(
    //         [stakingPoolAddress, stakingPoolAddress2], [depositDataInStake.signature, depositDataInStake2.signature], [depositDataRootInStake, depositDataRootInStake2])
    //     let nodeStakeTxRecipient = await nodeStakeTx.wait()
    //     console.log("node stake tx gas: ", nodeStakeTxRecipient.gasUsed.toString())

    //     // check state
    //     expect((await ethers.provider.getBalance(stakingPoolAddress)).toString()).to.equal(web3.utils.toWei("0", 'ether'))
    //     expect(await contractStakingPool.getStatus()).to.equal(2)
    //     expect(await contractStakingPool.getStatus()).to.equal(2)

    //     expect((await ethers.provider.getBalance(stakingPoolAddress2)).toString()).to.equal(web3.utils.toWei("0", 'ether'))
    //     expect(await contractStakingPool2.getStatus()).to.equal(2)

    //     expect((await ethers.provider.getBalance(this.ContractDepositContract.address)).toString()).to.equal("13391287000069000000000069")

    //     expect((await this.ContractStafiStakingPoolManager.getNodeStakingPoolCount(this.AccountNode1.address)).toString()).to.equal("2")
    //     expect((await this.ContractStafiStakingPoolManager.getNodeStakingPoolAt(this.AccountNode1.address, 0))).to.equal(stakingPoolAddress)
    //     expect((await this.ContractStafiStakingPoolManager.getNodeStakingPoolAt(this.AccountNode1.address, 1))).to.equal(stakingPoolAddress2)
    //     expect((await ethers.provider.getBalance(this.ContractStafiEther.address)).toString()).to.equal("11210863318720567060895")

    // })

    it("super node should deposit/stake success", async function () {
        console.log("latest block: ", await time.latestBlock())
        // enable deposit
        await this.ContractStafiSuperNode.connect(this.Admin).setSuperNodeDepositEnabled(true)

        // user deposit
        let userDepositTx = await this.ContractStafiUserDeposit.connect(this.AccountUser1).deposit({ from: this.AccountUser1.address, value: web3.utils.toWei('68', 'ether') })
        let userDepositTxRecipient = await userDepositTx.wait()
        console.log("user deposit tx gas: ", userDepositTxRecipient.gasUsed.toString())

        expect((await ethers.provider.getBalance(this.ContractStafiEther.address)).toString()).to.equal("11278863318720567060895")
        expect((await this.ContractStafiEther.balanceOf(this.ContractStafiUserDeposit.address)).toString()).to.equal("11278863318720567060895");

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
        await this.ContractStafiSuperNode.connect(this.TrustNode1).voteWithdrawCredentials([depositDataInDeposit.pubkey, depositDataInDeposit2.pubkey], [true, true])
        await this.ContractStafiSuperNode.connect(this.TrustNode2).voteWithdrawCredentials([depositDataInDeposit.pubkey, depositDataInDeposit2.pubkey], [true, true])

        // node deposit
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
        let depositDataRoot = beacon.getDepositDataRoot(depositDataInStake);
        let depositDataRoot2 = beacon.getDepositDataRoot(depositDataInStake2);

        let nodeStakeTx = await this.ContractStafiSuperNode.connect(this.AccountSuperNode1).stake(
            [depositDataInStake.pubkey, depositDataInStake2.pubkey], [depositDataInStake.signature, depositDataInStake2.signature], [depositDataRoot, depositDataRoot2])
        let nodeStakeTxRecipient = await nodeStakeTx.wait()
        console.log("super node stake tx gas: ", nodeStakeTxRecipient.gasUsed.toString())

        expect((await ethers.provider.getBalance(this.ContractStafiEther.address)).toString()).to.equal("11214863318720567060895")
        expect((await this.ContractStafiEther.balanceOf(this.ContractStafiUserDeposit.address)).toString()).to.equal("11214863318720567060895");
        // expect((await ethers.provider.getBalance(this.ContractDepositContract.address)).toString()).to.equal("13391351000069000000000069")

        expect((await this.ContractStafiSuperNode.getSuperNodePubkeyCount(this.AccountSuperNode1.address)).toString()).to.equal("2")
        expect((await this.ContractStafiSuperNode.getSuperNodePubkeyAt(this.AccountSuperNode1.address, 0))).to.equal("0x" + depositDataInStake.pubkey.toString("hex"))
        expect((await this.ContractStafiSuperNode.getSuperNodePubkeyAt(this.AccountSuperNode1.address, 1))).to.equal("0x" + depositDataInStake2.pubkey.toString("hex"))

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
        expect((await this.ContractStafiEther.balanceOf(this.ContractStafiUserDeposit.address)).toString()).to.equal(web3.utils.toBN("11214863318720567060895").add(web3.utils.toBN(web3.utils.toWei("24.80625", "ether"))).toString());
        expect((await this.ContractStafiEther.balanceOf(this.ContractStafiDistributor.address)).toString()).to.equal(web3.utils.toWei("10.19375", "ether"));
        expect((await ethers.provider.getBalance(this.ContractStafiFeePool.address)).toString()).to.equal(web3.utils.toWei("3", "ether"));

        // distribute fee
        let distributeSuperNodeFeeTx = await this.ContractStafiDistributor.connect(this.AccountUser2).distributeSuperNodeFee(web3.utils.toWei("3", "ether"), { from: this.AccountUser2.address })
        let distributeSuperNodeFeeTxRecipient = await distributeSuperNodeFeeTx.wait()
        console.log("distribute super node fee tx gas: ", distributeSuperNodeFeeTxRecipient.gasUsed.toString())

        // users: (3-3*1/10)*9/10 = 2.43
        // node+platform: 0.57
        expect((await this.ContractStafiEther.balanceOf(this.ContractStafiUserDeposit.address)).toString()).to.equal(web3.utils.toBN("11214863318720567060895").add(web3.utils.toBN(web3.utils.toWei("27.23625", "ether"))).toString());
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
        let setMerkleRootTx = await this.ContractStafiDistributor.connect(this.Admin).setMerkleRoot(0, tree.getHexRoot(), { from: this.Admin.address })
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
