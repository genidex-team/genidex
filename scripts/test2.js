// scripts/deploy_upgradeable_box.js
const { ethers, upgrades } = require('hardhat');

async function main() {

    const BoxV2 = await ethers.getContractFactory('BoxV2');
    const box = await BoxV2.attach('0x98E9Be264bA13a3dDB08d8CdF6DC31ABd138f015');

    console.log(await box.retrieve());
    await box.increment();
    console.log(await box.retrieve());


}

main();