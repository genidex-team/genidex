// scripts/deploy_upgradeable_box.js
const { ethers, upgrades, network } = require('hardhat');
const fn = require('../helpers/functions');
const data = require('../helpers/data');
const dataV2 = require('geni_data');
const geniDexHelper = require('../helpers/genidex.h')
const {utils} = require("genidex-sdk")

async function main () {

  const geniDexContract = await geniDexHelper.upgrade();
  let geniTokenAddress = dataV2.getGeniTokenAddress(network.name)
  let bnbAddress = data.get('bnbAddress');
  let arbAddress = data.get('arbAddress');
  let usdtAddress = data.get('usdtAddress');
  let daiAddress = data.get('daiAddress');
  let minOrderAmount;
  console.log('bnbAddress', bnbAddress);
  console.log('usdtAddress', usdtAddress);

  // let a = await geniDexContract.getAllMarkets();
  // console.log(a)
  // return;
  let markets = await geniDexHelper.getAllMarkets();
  console.log('markets', markets);

  // GENI_USDT - 1
  minOrderAmount = utils.parseBaseUnit("10");
  transaction = await geniDexContract.addMarket(geniTokenAddress, usdtAddress, minOrderAmount);
  fn.printGasUsed(transaction, '\naddMarket');

  // ETH_USDT - 2
  minOrderAmount = utils.parseBaseUnit("10");
  transaction = await geniDexContract.addMarket(ethers.ZeroAddress, usdtAddress, minOrderAmount);
  fn.printGasUsed(transaction, '\naddMarket');

  // GENI_ETH - 3
  minOrderAmount = utils.parseBaseUnit("0.0004");
  transaction = await geniDexContract.addMarket(geniTokenAddress, ethers.ZeroAddress, minOrderAmount);
  fn.printGasUsed(transaction, '\naddMarket');

  // ARB_DAI - 4
  minOrderAmount = utils.parseBaseUnit("10");
  transaction = await geniDexContract.addMarket(arbAddress, daiAddress, minOrderAmount);
  fn.printGasUsed(transaction, '\naddMarket');

  // ARB_ETH - 5
  minOrderAmount = utils.parseBaseUnit("0.0004");
  transaction = await geniDexContract.addMarket(arbAddress, ethers.ZeroAddress, minOrderAmount);
  fn.printGasUsed(transaction, '\naddMarket');

  // BNB_USDT - 6
  minOrderAmount = utils.parseBaseUnit("10");
  transaction = await geniDexContract.addMarket(bnbAddress, usdtAddress, minOrderAmount);
  fn.printGasUsed(transaction, '\naddMarket');

  await geniDexContract.updateTokenIsUSD(usdtAddress, true);
  await geniDexContract.updateTokenIsUSD(daiAddress, true);

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