const hre = require("hardhat");
const data = require("../../geni_data/index");
const geniDexHelper = require('../helpers/genidex.h');

async function main() {
  const network = hre.network.name;
  const [deployer] = await hre.ethers.getSigners();

  const geniDexAddress = data.getGeniDexAddress(network);
  const rewarderAddress = data.getGeniRewarder(network);

  if (!rewarderAddress) {
    throw new Error("Missing GeniRewarder address in data");
  }

  const geniDexContract = await geniDexHelper.getContract();

  const tx = await geniDexContract.connect(deployer).setGeniRewarder(rewarderAddress);
  await tx.wait();

  console.log(`✅ New rewarder: ${rewarderAddress}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});