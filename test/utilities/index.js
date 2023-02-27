const { ethers } = require("hardhat")
const { BigNumber } = require("ethers")

const BASE_TEN = 10
const ADDRESS_ZERO = "0x0000000000000000000000000000000000000000"

function encodeParameters(types, values) {
  const abi = new ethers.utils.AbiCoder()
  return abi.encode(types, values)
}


async function deploy(thisObject, contracts) {
  for (let i in contracts) {
    let contract = contracts[i]
    thisObject[contract[0]] = await contract[1].deploy(...(contract[2] || []))
    await thisObject[contract[0]].deployed()
  }
}


// Defaults to e18 using amount * 10^18
function getBigNumber(amount, decimals = 18) {
  return BigNumber.from(amount).mul(BigNumber.from(BASE_TEN).pow(decimals))
}

module.exports = {
  encodeParameters,
  deploy,
  getBigNumber,
  time: require("./time"),
  ADDRESS_ZERO,
  beacon: require("./beacon"),
  testing: require("./testing"),
}
