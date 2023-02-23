const { ethers, web3 } = require("hardhat")
const { time, beacon } = require("../test/utilities")

async function main() {
    // this.ContractStafiUserDeposit = await ethers.getContractAt("StafiUserDeposit", "0x6b3d7a220b96f3be9ff48e6be36a7e16f46b1393")
    // console.log(await this.ContractStafiUserDeposit.getBalance())
    // return


    this.signers = await ethers.getSigners()
    this.AccountAdmin = this.signers[0]

    this.AccountTrustNode1 = this.signers[1]

    this.AccountSuperNode1 = this.signers[2]

    this.AccountUser1 = this.signers[3]
    this.AccountNode1 = this.signers[4]

    console.log("trustNode1", this.AccountTrustNode1.address)
    console.log("user1", this.AccountUser1.address)
    console.log("node1", this.AccountNode1.address)
    console.log("admin", this.AccountAdmin.address)

    // await this.AccountAdmin.sendTransaction({
    //     to: "0xd59ba3B7119613ECc514f8DbAF2a81e7c9e302A2",
    //     value: web3.utils.toWei("0.1", "ether")
    // })
    this.ContractStafiSuperNode = await ethers.getContractAt("StafiSuperNode", "0xfa052FB4D0C530bDCBA7bF0C675515d3f12313b6")
    this.ContractStafiLightNode = await ethers.getContractAt("StafiLightNode", "0x4FEEA697bE14596c672681b92B1dfA41b654955b")
    this.ContractStafiUserDeposit = await ethers.getContractAt("StafiUserDeposit", "0x70C5744d377aE6E9926CcBCF19D501340CB26285")
    this.ContractStafiNetworkSettings = await ethers.getContractAt("StafiNetworkSettings", "0x430CB4F814EaA5816E3845f31A5EC3803bDa5B9F")
    this.ContractStafiNodeManager = await ethers.getContractAt("StafiNodeManager", "0x24aF013ef04c4F75B9DC7d7F1431c92ecf706117")
    this.ContractRETHToken = await ethers.getContractAt("RETHToken", "0xE6b876ED4e9191645484FC8940A35784381c2f9B")
    // this.ContractStafiUpgrade = await ethers.getContractAt("StafiUpgrade", "0x220aF91E212419f58Eb2c3B4D99376f7Fe23f58f")
    // await this.ContractRETHToken.connect(this.AccountAdmin).setBurnEnabled(true)
    // return
    // console.log(await this.ContractRETHToken.balanceOf("0x9b9B08aF1441BF50cd0d7a2D637049e2E36E06Cb"))
    console.log("exchange rate", await this.ContractRETHToken.getExchangeRate())
    // await this.ContractStafiNodeManager.connect(this.AccountAdmin).setNodeSuper("0xfe15cf269aA7cf067210d73AC228E37F89df3534", true)
    console.log("getSuperNodeExists", await this.ContractStafiNodeManager.getSuperNodeExists("0xfe15cf269aA7cf067210d73AC228E37F89df3534"))
    return
    // enable deposit
    // await this.ContractStafiLightNode.connect(this.AccountAdmin).setLightNodeDepositEnabled(true)
    // user deposit
    // let userDepositTx = await this.ContractStafiUserDeposit.connect(this.AccountAdmin).deposit({ from: this.AccountAdmin.address, value: web3.utils.toWei('350', 'ether') })
    // let userDepositTxRecipient = await userDepositTx.wait()
    // console.log("user deposit tx gas: ", userDepositTxRecipient.gasUsed.toString(), userDepositTxRecipient)


    // this.WithdrawalCredentials = '0x00325b04539edc57dfb7d0e3f414ae51f1a601608fa05c79a1660f531084d7ee'
    // await this.ContractStafiNetworkSettings.setWithdrawalCredentials(this.WithdrawalCredentials)
    console.log(await this.ContractStafiUserDeposit.getBalance())


    // await this.ContractStafiNodeManager.connect(this.AccountAdmin).setNodeSuper("0x99C6a3B0d131C996D9f65275fB5a196a8B57B583", true)
    console.log("withdrawalCredentials", await this.ContractStafiNetworkSettings.getWithdrawalCredentials())
    // console.log(await this.ContractStafiLightNode.getLightNodePubkeyCount("0x16ebaffbfa7a01d9711851e43dadd13ee2180c3f"))
    // console.log(await this.ContractStafiSuperNode.getSuperNodePubkeyCount("0x16ebaffbfa7a01d9711851e43dadd13ee2180c3f"))
    // console.log(await this.ContractStafiLightNode.getLightNodePubkeyCount(this.AccountNode1.address))
    // console.log(await this.ContractStafiSuperNode.getSuperNodePubkeyCount("0x99C6a3B0d131C996D9f65275fB5a196a8B57B583"))
    // console.log(await this.ContractStafiSuperNode.getSuperNodePubkeyStatus("0x920b903c9bbca7982e245db9888c4d0c092325f1b96bf41d532d161e9713834f9787eee0cbc508ab9465c63de254265e"))
    // console.log(await this.ContractStafiLightNode.getLightNodePubkeyStatus("0xa1feef93b0a56922f40cfcf10de226225b2e8905a88976a275568b79fcd14c16f9ba9cee60b97c8482398957da927825"))
    console.log("getLightNodeDepositEnabled", await this.ContractStafiLightNode.getLightNodeDepositEnabled())

    console.log("latest block: ", await time.latestBlock())
    // // node deposit
    // let depositDataInDeposit = {
    //     pubkey: beacon.getValidatorPubkey(),
    //     withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
    //     amount: BigInt(4000000000), // gwei
    //     signature: beacon.getValidatorSignature(),
    // };
    // 24000000000000000000
    // let depositDataInDeposit2 = {
    //     pubkey: beacon.getValidatorPubkey(),
    //     withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
    //     amount: BigInt(4000000000), // gwei
    //     signature: beacon.getValidatorSignature(),
    // };
    // let depositDataInDepositRoot = beacon.getDepositDataRoot(depositDataInDeposit);
    // let depositDataInDepositRoot2 = beacon.getDepositDataRoot(depositDataInDeposit2);

    // let nodeDepositTx = await this.ContractStafiLightNode.connect(this.AccountNode1).deposit(
    //     [depositDataInDeposit.pubkey, depositDataInDeposit2.pubkey], [depositDataInDeposit.signature, depositDataInDeposit2.signature], [depositDataInDepositRoot, depositDataInDepositRoot2],
    //     { from: this.AccountNode1.address, value: web3.utils.toWei('8', 'ether') })


    // let nodeDepositTx = await this.ContractStafiLightNode.connect(this.AccountNode1).deposit(
    //     ["0xb4f26713c30ffbdb1bda31eb72a73fea3e42d574ab6d5e0d81841c9373db15e3d34c479e202fc699e90c1a0163c459d9", "0x8520403a149079661459b4be1ce592adcc43944d9c4dce79088f62ccbd9b035c9aa10045d5237bbf3bbaaf862732052b"],
    //     ["0x863bceb130e60644bf9b2b6117db16d092565ca9af7cbe678a83641ba503f2c8ae3605209f60812f113d7688fdf0d9330b1f6cfe31265377827e5e5a280047118c13ead35f430fbc935170fcd2dfb6e011fdc0e8864cf1cc7980bea76178f4f5",
    //         "0xa695e8528bfc883cb86e78ce5eda231730154f4161df4da581c2293475012b83e3fd9d8d7da4783100035f34a354c509044c5299eb99df8aae9a1fb8f749653799b9a765b9b22336f48ac1c0806088a78a4c465c1f4205c06145cdfc2c157eb0"],
    //     ["0xf81b2369763750af86896ffd02dda78b575f900c12c9a6e988c541c13586ecbc", "0xe8d61e8a93f23248c488735c49c59a39a68ce0e9b2bfa44f104b32be99ac635a"],
    //     { from: this.AccountNode1.address, value: web3.utils.toWei('8', 'ether') })

    // let nodeDepositTxRecipient = await nodeDepositTx.wait()
    // console.log("light node deposit tx gas: ", nodeDepositTxRecipient.gasUsed.toString(), nodeDepositTxRecipient)











    // enable deposit
    // await this.ContractStafiSerNode.connect(this.AccountAdmin).setSuperNodeDepositEnabled(true)


    // beacon.getValidatorPubkey()
    // beacon.getValidatorPubkey()
    // // node deposit
    // let depositDataInDeposit = {
    //     pubkey: beacon.getValidatorPubkey(),
    //     withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
    //     amount: BigInt(1000000000), // gwei
    //     signature: beacon.getValidatorSignature(),
    // };

    // let depositDataInDeposit2 = {
    //     pubkey: beacon.getValidatorPubkey(),
    //     withdrawalCredentials: Buffer.from(this.WithdrawalCredentials.substr(2), 'hex'),
    //     amount: BigInt(1000000000), // gwei
    //     signature: beacon.getValidatorSignature(),
    // };
    // let depositDataInDepositRoot = beacon.getDepositDataRoot(depositDataInDeposit);
    // let depositDataInDepositRoot2 = beacon.getDepositDataRoot(depositDataInDeposit2);




    // "inputs": [
    //     [
    //       "0xb1f59a0d752fbd6bdf1090ff5e5ce5ef4443de9cc7c79cc40330060e765c4cb6ec205a217bd32af338f24a206adb4d72",
    //       "0xaa90f2ea9bb2c1ed2999e53743cc2e7972a31c73ae0427eb62f0597e64c173cdd8fc596c0f6d2a2a5d4d99638f889245"
    //     ],
    //     [
    //       "0x8389c3f06b9c1c44f8e550e9502202ffa2b217778917af014565e2fbed43bc4ca37ce84957179c6d2bd7ba3541e2ac321548049ab5a454f43bb9ab182726446eab5f0ca12a8ea54c76196452f883ed46cc5c89212f2a59a969b272973508b813",
    //       "0xb9035acf221ae5204879ebfd8b515bf84d3c4d2e3741375f606c975146fdb57cabc211a309bbec1b9d2fb3c3d43b0bc306eecbc48a472da55ee99a2da72af30e67f2bebaff220cd61de6124ce98b2cac8961984f8591fcc3ed96dd1ec49b5825"
    //     ],
    //     [
    //       "0x813cbbb64d17280eacfe723c9df3b48f4096247a2d77c54d144a2e387225f0ce",
    //       "0x1f2396c0f8da95787a4d095a26efac7dcc7b0a0aa16cdef5f11e8c26b0d52a8f"
    //     ]
    //   ],
    //   "names": [
    //     "_validatorPubkeys",
    //     "_validatorSignatures",
    //     "_depositDataRoots"
    //   ]

    // let nodeDepositTx = await this.ContractStafiSuperNode.connect(this.AccountSuperNode1).deposit(
    //     ["0xb1f59a0d752fbd6bdf1090ff5e5ce5ef4443de9cc7c79cc40330060e765c4cb6ec205a217bd32af338f24a206adb4d72", "0xaa90f2ea9bb2c1ed2999e53743cc2e7972a31c73ae0427eb62f0597e64c173cdd8fc596c0f6d2a2a5d4d99638f889245"],
    //     ["0x8389c3f06b9c1c44f8e550e9502202ffa2b217778917af014565e2fbed43bc4ca37ce84957179c6d2bd7ba3541e2ac321548049ab5a454f43bb9ab182726446eab5f0ca12a8ea54c76196452f883ed46cc5c89212f2a59a969b272973508b813",
    //         "0xb9035acf221ae5204879ebfd8b515bf84d3c4d2e3741375f606c975146fdb57cabc211a309bbec1b9d2fb3c3d43b0bc306eecbc48a472da55ee99a2da72af30e67f2bebaff220cd61de6124ce98b2cac8961984f8591fcc3ed96dd1ec49b5825"],
    //     ["0x813cbbb64d17280eacfe723c9df3b48f4096247a2d77c54d144a2e387225f0ce", "0x1f2396c0f8da95787a4d095a26efac7dcc7b0a0aa16cdef5f11e8c26b0d52a8f"])
    // let nodeDepositTxRecipient = await nodeDepositTx.wait()
    // console.log("super node deposit tx gas: ", nodeDepositTxRecipient.gasUsed.toString(), nodeDepositTxRecipient)

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
