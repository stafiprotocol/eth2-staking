const { ethers, web3 } = require("hardhat")
const { time, beacon } = require("../test/utilities")

async function main() {
    this.signers = await ethers.getSigners()
    this.AccountAdmin = this.signers[0]

    this.AccountProxyAdmin = this.signers[5]

    console.log("AccountProxyAdmin", this.AccountProxyAdmin.address)
    this.FactoryStafiWithdraw = await ethers.getContractFactory("StafiWithdraw", this.AccountAdmin)
    this.FactoryStafiWithdrawProxy = await ethers.getContractFactory("StafiWithdrawProxy", this.AccountAdmin)


    this.ContractStafiUpgrade = await ethers.getContractAt("StafiUpgrade", "0x7DB65B2ccDdBca73988205639ac58090f03F7cD9")



    this.ContractStafiWithdraw = await this.FactoryStafiWithdraw.deploy()
    await this.ContractStafiWithdraw.deployed()
    console.log("ContractStafiWithdraw address: ", this.ContractStafiWithdraw.address)

    this.ContractStafiWithdrawProxy = await this.FactoryStafiWithdrawProxy.deploy(this.ContractStafiWithdraw.address, this.AccountProxyAdmin.address, [])
    await this.ContractStafiWithdrawProxy.deployed()
    console.log("ContractStafiWithdrawProxy address: ", this.ContractStafiWithdrawProxy.address)



    await this.ContractStafiUpgrade.addContract("stafiWithdraw", this.ContractStafiWithdrawProxy.address)
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
