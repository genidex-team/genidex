require('@genidex/logger');

require("@nomicfoundation/hardhat-toolbox");
require('@nomicfoundation/hardhat-ethers');
require('@openzeppelin/hardhat-upgrades');
require("@nomicfoundation/hardhat-verify");
require('hardhat-gas-reporter');
require("hardhat-contract-sizer");

const env = require('./helpers/env');
env.loadDefaultEnv();

const data = require('geni_data');

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
    strict: true,
    only: ['GeniDex']
  },
  solidity: {
    compilers: [
      {
        version: "0.8.27",
        settings: {
          evmVersion: "cancun",
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 800,
          },
        },
      }
    ]
  },
  defaultNetwork: 'hardhat',
  data: {
    gasPrice: 2000n*10n**6n,// ETH - wei/gas // ethereum
    // gasPrice: 15n*10n**6n,// ETH - wei/gas // optimism
    // gasPrice: 60n*10n**9n,// ETH - wei/gas
    // gasPrice: 600n*10n**6n,// ETH - wei/gas
    // gasPrice: 13n*10n**9n/1000n,// Arbitrum - wei/gas
    ethPrice: 3000 //  USD/ETH
  },
  gasReporter: {
    enabled: false,
    currency: 'USD',
    gasPrice: 60
  },
  networks: data.getNetworkConfig(),
  etherscan: data.getEtherscanConfig(),
  sourcify: {
    enabled: false
  },
  mocha: {
    timeout: 120000,
  },
};
