// scripts/deploy_upgradeable_box.js
const { ethers, upgrades } = require('hardhat');
const fn = require('../helpers/functions');
const data = require('../helpers/data');
const geniDexHelper = require('../helpers/genidex.h')

async function main () {

  const geniDexContract = await geniDexHelper.upgrade();
  let opAddress = data.get('opAddress');
  let arbAddress = data.get('arbAddress');
  let usdtAddress = data.get('usdtAddress');
  let daiAddress = data.get('daiAddress');
  console.log('opAddress', opAddress);
  console.log('usdtAddress', usdtAddress);

  let markets = await geniDexHelper.getAllMarkets();
  console.log('markets', markets);

  // // gOP_USDT mainnet
  // usdtAddress = '0x6B175474E89094C44Da98b954EedeAC495271d0F';
  // let transaction = await geniDexContract.addMarket(opAddress, usdtAddress);
  // fn.printGasUsed(transaction, '\naddMarket');

  // gOP_gUSDT - 1
  transaction = await geniDexContract.addMarket(opAddress, usdtAddress);
  fn.printGasUsed(transaction, '\naddMarket');

  // gETH_gUSDT - 2
  transaction = await geniDexContract.addMarket(ethers.ZeroAddress, usdtAddress);
  fn.printGasUsed(transaction, '\naddMarket');

  // gOP_gETH - 3
  transaction = await geniDexContract.addMarket(opAddress, ethers.ZeroAddress);
  fn.printGasUsed(transaction, '\naddMarket');

  // gARB_gDAI - 4
  transaction = await geniDexContract.addMarket(arbAddress, daiAddress);
  fn.printGasUsed(transaction, '\naddMarket');

  // gARB_gETH - 5
  transaction = await geniDexContract.addMarket(arbAddress, ethers.ZeroAddress);
  fn.printGasUsed(transaction, '\naddMarket');

  await geniDexContract.updateMarketIsRewardable(1, true);
  await geniDexContract.updateMarketIsRewardable(2, true);
  await geniDexContract.updateMarketIsRewardable(3, true);
  await geniDexContract.updateMarketIsRewardable(4, true);
  await geniDexContract.updateMarketIsRewardable(5, true);

  // await geniDexContract.updateUSDMarketID(ethers.ZeroAddress, 2);

  markets = await geniDexHelper.getAllMarkets();
  console.log('markets', markets);

}

main();