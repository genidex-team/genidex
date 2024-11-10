// scripts/deploy_upgradeable_box.js
const { ethers, upgrades } = require('hardhat');


async function main () {
  const Box = await ethers.getContractFactory('Box');
  console.log('Deploying Box...');
  const [owner] = await ethers.getSigners();
  const box = await upgrades.deployProxy(Box, [owner.address], {kind: 'uups', initializer: 'store' });
  await box.waitForDeployment();
  console.log(box);
  console.log('Box deployed to:', box.target);
  let rs = await box.retrieve();
  console.log(rs);
}

main();