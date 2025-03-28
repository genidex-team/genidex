const hre = require("hardhat");

const data = require('../../geni_data/index');

async function main() {
  const contractAddress = data.getGeniDexAddress(hre.network.name);

  const tokenAddresses = [
    "0xd0EC100F1252a53322051a95CF05c32f0C174354",
    "0xaB837301d12cDc4b97f1E910FC56C9179894d9cf",
    "0xd0EC100F1252a53322051a95CF05c32f0C174354"
  ];

  const contract = await hre.ethers.getContractAt("GeniDex", contractAddress);

  const tokenInfos = await contract.getTokensInfo(tokenAddresses);

  tokenInfos.forEach((info, index) => {
    console.log(`Token ${index + 1}:`);
    console.log(`  Address: ${info.tokenAddress}`);
    console.log(`  isUSD: ${info.isUSD}`);
    console.log(`  Decimals: ${info.decimals}`);
    console.log(`  usdMarketID: ${info.usdMarketID}`);
    console.log("---------------------------");
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});