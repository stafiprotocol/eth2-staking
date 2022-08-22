const { ethers } = require("hardhat")
const { expect, assert } = require("chai")
const { time, beacon } = require("./utilities")

describe("StafiUserDeposit", function () {
    before(async function () {
        this.signers = await ethers.getSigners()

        this.AccountAdmin = this.signers[0]
        this.AccountUser1 = this.signers[1]
        this.AccountNode1 = this.signers[2]



        this.FactoryStafiNodeDeposit = await ethers.getContractFactory("StafiNodeDeposit", this.AccountAdmin)
        this.FactoryStafiUserDeposit = await ethers.getContractFactory("StafiUserDeposit", this.AccountAdmin)

        this.FactoryStafiNetworkBalances = await ethers.getContractFactory("StafiNetworkBalances", this.AccountAdmin)
        this.FactoryStafiNetworkWithdrawal = await ethers.getContractFactory("StafiNetworkWithdrawal", this.AccountAdmin)

        this.FactoryStafiNodeManager = await ethers.getContractFactory("StafiNodeManager", this.AccountAdmin)

        this.FactoryStafiStakingPoolQueue = await ethers.getContractFactory("StafiStakingPoolQueue", this.AccountAdmin)
        this.FactoryStafiStakingPoolManager = await ethers.getContractFactory("StafiStakingPoolManager", this.AccountAdmin)
        this.FactoryStafiStakingPoolDelegate = await ethers.getContractFactory("StafiStakingPoolDelegate", this.AccountAdmin)

        this.FactoryStafiNetworkSettings = await ethers.getContractFactory("StafiNetworkSettings", this.AccountAdmin)
        this.FactoryStafiStakingPoolSettings = await ethers.getContractFactory("StafiStakingPoolSettings", this.AccountAdmin)


        this.FactoryStafiStorage = await ethers.getContractFactory("StafiStorage", this.AccountAdmin)
        this.FactoryAddressSetStorage = await ethers.getContractFactory("AddressSetStorage", this.AccountAdmin)
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



        this.ContractAddressSetStorage = await this.FactoryAddressSetStorage.deploy(this.ContractStafiStorage.address)
        await this.ContractAddressSetStorage.deployed()
        console.log("contract addressSetStorage address: ", this.ContractAddressSetStorage.address)
        await this.ContractStafiUpgrade.addContract("addressSetStorage", this.ContractAddressSetStorage.address)

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



        this.ContractStafiNetworkBalances = await this.FactoryStafiNetworkBalances.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiNetworkBalances.deployed()
        console.log("contract stafiNetworkBalances address: ", this.ContractStafiNetworkBalances.address)
        await this.ContractStafiUpgrade.addContract("stafiNetworkBalances", this.ContractStafiNetworkBalances.address)

        this.ContractStafiNetworkWithdrawal = await this.FactoryStafiNetworkWithdrawal.deploy(this.ContractStafiStorage.address)
        await this.ContractStafiNetworkWithdrawal.deployed()
        console.log("contract stafiNetworkWithdrawal address: ", this.ContractStafiNetworkWithdrawal.address)
        await this.ContractStafiUpgrade.addContract("stafiNetworkWithdrawal", this.ContractStafiNetworkWithdrawal.address)



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


    })

    it("should deposit success", async function () {
        console.log("latest time: ", await time.latest())
        // Get validator deposit data
        let depositData = {
            pubkey: beacon.getValidatorPubkey(),
            withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
            amount: BigInt(4000000000), // gwei
            signature: beacon.getValidatorSignature(),
        };

        let depositDataRoot = beacon.getDepositDataRoot(depositData);


        await this.ContracStafiNodeDeposit.connect(this.AccountNode1).deposit(depositData.pubkey, depositData.signature, depositDataRoot, { from: this.AccountNode1.address, value: web3.utils.toWei('4', 'ether') })

    })
})