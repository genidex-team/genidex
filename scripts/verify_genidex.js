// scripts/upgrade_box.js
const { ethers, upgrades } = require('hardhat');
const fn = require('../helpers/functions');
const data = require('../helpers/data');
const geniDexHelper = require('../helpers/genidex.h')

async function main () {
  let geniDexAddress = data.get('geniDexAddress');
  await geniDexHelper.verify(geniDexAddress);
}

main();