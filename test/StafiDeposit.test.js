const { ethers, web3 } = require("hardhat")
const { expect } = require("chai")
const { time, beacon } = require("./utilities")

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



        this.FactoryStafiNodeDeposit = await ethers.getContractFactory("StafiNodeDeposit", this.AccountAdmin)
        this.FactoryStafiUserDeposit = await ethers.getContractFactory("StafiUserDeposit", this.AccountAdmin)

        this.FactoryStafiNetworkBalances = await ethers.getContractFactory("StafiNetworkBalances", this.AccountAdmin)
        this.FactoryStafiNetworkWithdrawal = await ethers.getContractFactory("StafiNetworkWithdrawal", this.AccountAdmin)
        this.FactoryStafiDistributor = await ethers.getContractFactory("StafiDistributor", this.AccountAdmin)
        this.FactoryStafiFeePool = await ethers.getContractFactory("StafiFeePool", this.AccountAdmin)
        this.FactoryStafiSuperNodeFeePool = await ethers.getContractFactory("StafiSuperNodeFeePool", this.AccountAdmin)

        this.FactoryStafiNodeManager = await ethers.getContractFactory("StafiNodeManager", this.AccountAdmin)
        this.FactoryStafiSuperNode = await ethers.getContractFactory("StafiSuperNode", this.AccountAdmin)

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

        expect(await contractStakingPool.getStatus()).to.equal(1)
        expect(await contractStakingPool.getNodeDepositAssigned()).to.equal(true)
        expect(await contractStakingPool.getUserDepositAssigned()).to.equal(true)
        expect(await contractStakingPool.getWithdrawalCredentialsMatch()).to.equal(false)
        expect((await contractStakingPool.getNodeDepositBalance()).toString()).to.equal(web3.utils.toWei("4", 'ether'))
        expect((await contractStakingPool.getUserDepositBalance()).toString()).to.equal(web3.utils.toWei("28", 'ether'))
        expect((await ethers.provider.getBalance(stakingPoolAddress)).toString()).to.equal(web3.utils.toWei("28", 'ether'))

        // trust node vote withdrawCredentials
        await contractStakingPool.connect(this.AccountTrustNode1).voteWithdrawCredentials()

        expect(await contractStakingPool.getWithdrawalCredentialsMatch()).to.equal(true)

        // node stake
        let depositDataInStake = {
            pubkey: depositData.pubkey,
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(28000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };
        let depositDataRootInStake = beacon.getDepositDataRoot(depositDataInStake);

        let nodeStakeTx = await contractStakingPool.connect(this.AccountNode1).stake([depositDataInStake.signature], [depositDataRootInStake])
        let nodeStakeTxRecipient = await nodeStakeTx.wait()
        console.log("node stake tx gas: ", nodeStakeTxRecipient.gasUsed.toString())

        // check state
        expect((await ethers.provider.getBalance(stakingPoolAddress)).toString()).to.equal(web3.utils.toWei("0", 'ether'))
        expect(await contractStakingPool.getStatus()).to.equal(2)


        expect((await ethers.provider.getBalance(this.ContractStafiNetworkWithdrawal.address)).toString()).to.equal(web3.utils.toWei("0", 'ether'))

        // start: total 32eth, node 4eth, users 28eth 
        // end: total 38eth, platform 0.6eth, node 4 + 5.4*1/8 + 5.4*7/8*1/10 = 5.1475, users 28 + 5.4*7/8*9/10 = 32.2525
        // send deposit and reward eth to StafiNetworkWithdrawal contract
        // await this.AccountWithdrawer1.sendTransaction({
        //     to: this.ContractStafiNetworkWithdrawal.address,
        //     value: web3.utils.toWei("38", "ether")
        // })

        // expect((await ethers.provider.getBalance(this.ContractStafiNetworkWithdrawal.address)).toString()).to.equal(web3.utils.toWei("0", 'ether'))
        // expect((await ethers.provider.getBalance(this.ContractStafiEther.address)).toString()).to.equal(web3.utils.toWei("38", 'ether'))
        // let nodeBalanceBefore = await ethers.provider.getBalance(this.AccountNode1.address)

        // // distribute deposit and reward to node/users by trust node
        // let startBalance = web3.utils.toWei("32", "ether")
        // let endBalance = web3.utils.toWei("38", "ether")
        // await this.ContractStafiNetworkWithdrawal.connect(this.AccountTrustNode1).withdrawStakingPool(stakingPoolAddress, startBalance, endBalance)
        // let nodeBalanceAfter = await ethers.provider.getBalance(this.AccountNode1.address)

        // expect(nodeBalanceAfter.sub(nodeBalanceBefore).toString()).to.equal(web3.utils.toWei("5.1475", "ether"))
        // expect((await ethers.provider.getBalance(this.ContractStafiNetworkWithdrawal.address)).toString()).to.equal(web3.utils.toWei("0.6", 'ether'))
        // expect((await ethers.provider.getBalance(this.ContractStafiEther.address)).toString()).to.equal(web3.utils.toWei("32.2525", 'ether'))
    })


    it("super node should stake success", async function () {
        console.log("latest block: ", await time.latestBlock())

        // user deposit
        let userDepositTx = await this.ContractStafiUserDeposit.connect(this.AccountUser1).deposit({ from: this.AccountUser1.address, value: web3.utils.toWei('68', 'ether') })
        let userDepositTxRecipient = await userDepositTx.wait()
        console.log("user deposit tx gas: ", userDepositTxRecipient.gasUsed.toString())

        expect((await ethers.provider.getBalance(this.ContractStafiEther.address)).toString()).to.equal(web3.utils.toWei("68", 'ether'))
        expect((await this.ContractStafiEther.balanceOf(this.ContractStafiUserDeposit.address)).toString()).to.equal(web3.utils.toWei("68", "ether"));
        expect((await this.ContractRETHToken.balanceOf(this.AccountUser1.address)).toString()).to.equal(web3.utils.toWei("68", "ether"));
        // node deposit
        let depositDataInStake = {
            pubkey: beacon.getValidatorPubkey(),
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(32000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };

        let depositDataInStake2 = {
            pubkey: beacon.getValidatorPubkey(),
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(32000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };
        let depositDataRoot = beacon.getDepositDataRoot(depositDataInStake);
        let depositDataRoot2 = beacon.getDepositDataRoot(depositDataInStake2);

        let nodeStakeTx = await this.ContractStafiSuperNode.connect(this.AccountSuperNode1).stake(
            [depositDataInStake.pubkey, depositDataInStake2.pubkey], [depositDataInStake.signature, depositDataInStake2.signature], [depositDataRoot, depositDataRoot2])
        let nodeStakeTxRecipient = await nodeStakeTx.wait()
        console.log("super node stake tx gas: ", nodeStakeTxRecipient.gasUsed.toString())

        expect((await ethers.provider.getBalance(this.ContractStafiEther.address)).toString()).to.equal(web3.utils.toWei("4", 'ether'))
        expect((await this.ContractStafiEther.balanceOf(this.ContractStafiUserDeposit.address)).toString()).to.equal(web3.utils.toWei("4", "ether"));

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


    })
})