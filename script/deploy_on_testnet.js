const { ethers, web3 } = require("hardhat")


async function main() {
    this.signers = await ethers.getSigners()
    this.AccountAdmin = this.signers[0]
    this.AccountTrustNode1 = this.signers[1]
    this.AccountSuperNode1 = this.signers[2]
    this.AccountProxyAdmin = this.signers[5]

    this.FactoryStafiNodeDeposit = await ethers.getContractFactory("StafiNodeDeposit", this.AccountAdmin)
    this.FactoryStafiUserDeposit = await ethers.getContractFactory("StafiUserDeposit", this.AccountAdmin)

    this.FactoryStafiNetworkBalances = await ethers.getContractFactory("StafiNetworkBalances", this.AccountAdmin)
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

    this.FactoryStafiWithdraw = await ethers.getContractFactory("StafiWithdraw", this.AccountAdmin)
    this.FactoryStafiWithdrawProxy = await ethers.getContractFactory("StafiWithdrawProxy", this.AccountAdmin)




    this.ContractStafiStorage = await this.FactoryStafiStorage.deploy()
    await this.ContractStafiStorage.deployed()
    console.log("contract stafiStorage address: ", this.ContractStafiStorage.address)


    this.ContractStafiUpgrade = await this.FactoryStafiUpgrade.deploy(this.ContractStafiStorage.address)
    await this.ContractStafiUpgrade.deployed()
    console.log("contract stafiUpgrade address: ", this.ContractStafiUpgrade.address)
    await this.ContractStafiUpgrade.initThisContract()



    this.ContractStafiEther = await this.FactoryStafiEther.deploy(this.ContractStafiStorage.address)
    await this.ContractStafiEther.deployed()
    console.log("contract stafiEther address: ", this.ContractStafiEther.address)
    await this.ContractStafiUpgrade.addContract("stafiEther", this.ContractStafiEther.address)

    // Notice: need update on different network
    // zhejiang: 0x4242424242424242424242424242424242424242
    // sepolia: 0x7f02C3E3c98b133055B8B348B2Ac625669Ed295D
    // goerli: 0xff50ed3d0ec03ac01d4c79aad74928bff48a7b2b
    // hoodi: 0x00000000219ab540356cBB839Cbe05303d7705Fa

    // this.ContractDepositContract = await this.FactoryDepositContract.deploy()
    // await this.ContractDepositContract.deployed()

    this.ContractDepositContractAddress = "0x00000000219ab540356cBB839Cbe05303d7705Fa"
    console.log("contract ethDepositContract address: ", this.ContractDepositContractAddress)
    await this.ContractStafiUpgrade.addContract("ethDeposit", this.ContractDepositContractAddress)


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

    this.ContractStafiWithdraw = await this.FactoryStafiWithdraw.deploy()
    await this.ContractStafiWithdraw.deployed()
    console.log("ContractStafiWithdraw address: ", this.ContractStafiWithdraw.address)

    this.ContractStafiWithdrawProxy = await this.FactoryStafiWithdrawProxy.deploy(this.ContractStafiWithdraw.address, this.AccountProxyAdmin.address, [])
    await this.ContractStafiWithdrawProxy.deployed()
    console.log("ContractStafiWithdrawProxy address: ", this.ContractStafiWithdrawProxy.address)
    await this.ContractStafiUpgrade.addContract("stafiWithdraw", this.ContractStafiWithdrawProxy.address)



    // set params
    await this.ContractStafiUpgrade.initStorage(true)

    this.WithdrawalCredentials = '0x010000000000000000000000' + this.ContractStafiWithdrawProxy.address.substring(2)
    console.log("WithdrawalCredentials: ", this.WithdrawalCredentials)
    await this.ContractStafiNetworkSettings.setWithdrawalCredentials(this.WithdrawalCredentials)

    await this.ContractStafiNodeManager.connect(this.AccountAdmin).setNodeTrusted(this.AccountTrustNode1.address, true)
    await this.ContractStafiNodeManager.connect(this.AccountAdmin).setNodeSuper(this.AccountSuperNode1.address, true)

    // enable deposit
    await this.ContractStafiLightNode.connect(this.AccountAdmin).setLightNodeDepositEnabled(true)
    await this.ContractStafiSuperNode.connect(this.AccountAdmin).setSuperNodeDepositEnabled(true)

    console.log("admin address: ", this.AccountAdmin.address, (await ethers.provider.getBalance(this.AccountAdmin.address)).toString())
    console.log("proxy admin address:", this.AccountProxyAdmin.address)
    console.log("trust node address:", this.AccountTrustNode1.address)
    console.log("super node address:", this.AccountSuperNode1.address)
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
