const logger = require('./helpers/logger');
logger.overrideLog();
require('./helpers/colors');

require("@nomicfoundation/hardhat-toolbox");
require('@nomicfoundation/hardhat-ethers');
require('@openzeppelin/hardhat-upgrades');
require("@nomicfoundation/hardhat-verify");
require('hardhat-gas-reporter');

const env = require('./helpers/env');
env.loadDefaultEnv();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  // solidity: "0.8.0",
  solidity: {
    compilers: [
      {
        version: "0.8.24",
        settings: {
          evmVersion: "cancun",
          // viaIR: true,
          optimizer: {
            enabled: true,
            runs: 20000,
          },
        },
      }
    ]
  },
  defaultNetwork: 'hardhat',
  data: {
    gasPrice: 60n*10n**9n,// ETH - wei/gas
    // gasPrice: 600n*10n**6n,// ETH - wei/gas
    // gasPrice: 13n*10n**9n/1000n,// Arbitrum - wei/gas
    ethPrice: 3000 //  USD/ETH
  },
  gasReporter: {
    enabled: false,
    currency: 'USD',
    gasPrice: 60
  },
  networks: {
    hardhat: {
      hardfork: "cancun",
      // forking: {
      //   // url: "https://mainnet.infura.io/v3/" + env.get('INFURA_API_KEY'),
      //   url: "https://optimism-mainnet.infura.io/v3/" + env.get('INFURA_API_KEY'),
      //   blockNumber: 126723376
      // },
      allowUnlimitedContractSize: true
    },
    geni: {
      chainId: 31339,
      url: "https://rpc.genidex.net",
      accounts: [
        '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
        '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d',
        '0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a',
        '0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6',
        '0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a',
        '0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba',
        '0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e',
        '0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356',
        '0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97',
        '0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6'
      ]
    },
    ganache_eth_mainnet: {
      chainId: 1,
      url: 'http://127.0.0.1:9991',
    },
    ganache_op_mainnet: {
      chainId: 10,
      url: 'http://127.0.0.1:9992',
    },
    sepolia: {
      url: 'https://sepolia.infura.io/v3/' + env.get('INFURA_API_KEY'),
      accounts: [
        env.get('PRIVATE_KEY_0'),
        env.get('PRIVATE_KEY_1'),
        env.get('PRIVATE_KEY_2'),
      ]
    },
    op_sepolia: {
      chainId: 11155420,
      url: 'https://sepolia.optimism.io',
      accounts: [
        env.get('PRIVATE_KEY_0'),
        env.get('PRIVATE_KEY_1'),
        env.get('PRIVATE_KEY_2'),
      ]
    }
  },
  etherscan: {
    apiKey: {
      op_sepolia: env.get('ETHERSCAN_OP_API_KEY')
    },
    customChains: [
      {
        network: "localhost",
        chainId: 31337,
        urls: {
          apiURL: "http://localhost:55787/api",
          browserURL: "http://localhost:55787"
        }
      },
      {
        network: "op_sepolia",
        chainId: 11155420,
        urls: {
          apiURL: "https://api-sepolia-optimism.etherscan.io/api",
          browserURL: "https://sepolia-optimism.etherscan.io/"
        }
      }
    ]
  },
  sourcify: {
    enabled: false
  },
  mocha: {
    timeout: 120000,
  },
};
