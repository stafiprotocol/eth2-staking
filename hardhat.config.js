require("hardhat-contract-sizer")
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-web3");
require("@nomiclabs/hardhat-etherscan");

// set proxy
const { ProxyAgent, setGlobalDispatcher } = require("undici");
const proxyAgent = new ProxyAgent('http://127.0.0.1:7890'); // change to yours
setGlobalDispatcher(proxyAgent)

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.7.6",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      forking: {
        url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
        blockNumber: 15431470
      }
    },
    local: {
      url: 'http://127.0.0.1:8545',
      accounts: [
        `${process.env.ACCOUNT1}`,
        `${process.env.ACCOUNT2}`,
        `${process.env.ACCOUNT3}`,
        `${process.env.ACCOUNT4}`,
        `${process.env.ACCOUNT5}`,
        `${process.env.ACCOUNT6}`,
      ],
    },
    mainnet: {
      url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: [
        `${process.env.ACCOUNT1}`,
        `${process.env.ACCOUNT2}`,
        `${process.env.ACCOUNT3}`,
        `${process.env.ACCOUNT4}`,
        `${process.env.ACCOUNT5}`,
        `${process.env.ACCOUNT6}`,
      ],
    },
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: [
        `${process.env.ACCOUNT1}`,
        `${process.env.ACCOUNT2}`,
        `${process.env.ACCOUNT3}`,
        `${process.env.ACCOUNT4}`,
        `${process.env.ACCOUNT5}`,
        `${process.env.ACCOUNT6}`,
      ],
    }
  },
  defaultNetwork: "hardhat",
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: false,
    disambiguatePaths: false,
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: `${process.env.ETHERSCAN_KEY}`
  }
};

