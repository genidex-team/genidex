
const { ethers, network } = require("hardhat");
const data = require('geni_data');
const config = require('../../config/config');

const {GeniDex, NetworkName} = require("genidex-sdk");
const {Admin} = require("genidex-sdk/admin")

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(`Deployer ${deployer.address} on ${network.name}`);
    const genidexAddress = data.getGeniDexAddress(network.name);

    // deploy new access manager
    const Manager = await ethers.getContractFactory("GeniAccessManager");
    const manager = await Manager.deploy();
    await manager.waitForDeployment();
    console.log("AccessManager deployed:", manager.target);

    // store new access manager address
    data.setAccessManagerAddress(network.name, manager.target)

    // update updateAuthority
    try{
        const oldAuthority = await config.adminSDK.getAuthority();
        console.log({oldAuthority});
        const oldManager = await ethers.getContractAt("GeniAccessManager", oldAuthority, deployer);
        const tx = await oldManager.updateAuthority(genidexAddress, manager.target);
        receipt = await tx.wait();
        console.log('receipt.hash', receipt.hash);
        const newAuthority = await config.adminSDK.getAuthority();
        console.log({newAuthority});
    }catch(error){
        console.log('Not found GeniDex Contract')
    }

    process.exit();
}

main().catch((e) => {
    console.error(e);
    process.exit(1);
});
