const {ethers, network} = require("hardhat");
const data = require("geni_data");
const geniDexHelper = require('../helpers/genidex.h');
const config = require('../config/config');
let adminSDK;

async function main() {
  // await config.init();
  adminSDK = config.adminSDK;
  const [deployer, upgrader, pauser, operator] = await ethers.getSigners();

  const rewarderAddress = data.getGeniRewarder(network.name);

  if (!rewarderAddress) {
    throw new Error("Missing GeniRewarder address in data");
  }

  const tx = await adminSDK.setGeniRewarder({
    signer: operator,
    rewarderAddress
  });
  await tx.wait();

  console.log(`✅ New rewarder: ${rewarderAddress}`);
  process.exit();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});