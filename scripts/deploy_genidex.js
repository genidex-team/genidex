// scripts/deploy_upgradeable_box.js
const { ethers, upgrades } = require('hardhat');
const hre = require("hardhat");
const fn = require('../helpers/functions');
const data = require('../helpers/data');
const geniDexHelper = require('../helpers/genidex.h')

async function main () {

  const geniDexContract = await geniDexHelper.deploy();
  // const geniDexContract = await geniDexHelper.upgrade();
  

}

main();