
const {ethers, upgrades, network, run} = require("hardhat");
const { getArbitrumNetwork } = require('@arbitrum/sdk');
const data = require('geni_data');


async function main() {
  const [deployer] = await ethers.getSigners();
  const initialOwner = deployer.address;
  const recipient = deployer.address;
  const proxyAddress = data.getGeniDexAddress(network.name);
  const imlpAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress)
   await run("verify:verify", {
      address: imlpAddress
    });

  // console.log({proxyAddress});return;
  const placeholderAddress = data.getPlaceholderUUPS(network.name);
  const constructorArgs = [
    placeholderAddress,
    '0x'
  ];

  try {
    await run("verify:verify", {
      contract: "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy",
      address: proxyAddress,
      constructorArguments: constructorArgs,
    });

    console.log("✅ Verification successful!");
  } catch (err) {
    console.error("❌ Verification failed:");
    console.error(err.message || err);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Script error:", error);
    process.exit(1);
  });
