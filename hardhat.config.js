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
          // viaIR: true,
          optimizer: {
            enabled: true,
            runs: 200
          },
        },
      }
    ]
  },
  defaultNetwork: 'hardhat',
  data: {
    gasPrice: 60n*10n**9n,// ETH - wei/gas
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
      // forking: {
      //   // url: "https://mainnet.infura.io/v3/" + env.get('INFURA_API_KEY'),
      //   url: "https://optimism-mainnet.infura.io/v3/" + env.get('INFURA_API_KEY'),
      //   blockNumber: 126723376
      // },
      allowUnlimitedContractSize: true,
    },
    geni: {
      chainId: 31338,
      url: "https://rpc.genidex.net"
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
        env.get('SEPOLIA_PRIVATE_KEY'),
        '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80', //acount 0 - npx hardhat node
        '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d' //acount 1 - npx hardhat node
      ]
    },
    op_sepolia: {
      chainId: 11155420,
      url: 'https://sepolia.optimism.io',
      accounts: [
        env.get('SEPOLIA_PRIVATE_KEY')
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
  compilers: {
    solc: {}
  }
};
