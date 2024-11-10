// scripts/upgrade_box.js
const { ethers, upgrades } = require('hardhat');

async function main () {
  const BoxV2 = await ethers.getContractFactory('BoxV2');
  console.log('Upgrading Box...');
  await upgrades.upgradeProxy('0x748F4fCcfDb791Fa20c1c0321035cc6D7b873d0e', BoxV2, {kind: 'uups'});
  console.log('Box upgraded');
}

main();