
const { ethers, network } = require("hardhat");
const data = require('geni_data');

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(`Deployer ${deployer.address} on ${network.name}`);

    const Manager = await ethers.getContractFactory("GeniAccessManager");
    const manager = await Manager.deploy(deployer.address);
    await manager.waitForDeployment();

    console.log("AccessManager deployed:", manager.target);
    data.setAccessManagerAddress(network.name, manager.target)
}

main().catch((e) => {
    console.error(e);
    process.exit(1);
});
