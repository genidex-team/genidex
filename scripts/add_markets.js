// scripts/deploy_upgradeable_box.js
const { ethers, upgrades, network } = require('hardhat');
const fn = require('../helpers/functions');
const data = require('../helpers/data');
const dataV2 = require('geni_data');
const geniDexHelper = require('../helpers/genidex.h')
const {utils} = require("genidex-sdk")
const {Admin} = require("genidex-sdk/admin")
const config = require('../config/config');
let adminSDK;
let owner;

async function main () {

  await config.init();
  adminSDK = config.adminSDK;
  [owner] = await ethers.getSigners();

  const geniDexContract = await geniDexHelper.upgrade();
  let geniTokenAddress = dataV2.getGeniTokenAddress(network.name)
  let bnbAddress = data.get('bnbAddress');
  let arbAddress = data.get('arbAddress');
  let usdtAddress = data.get('usdtAddress');
  let daiAddress = data.get('daiAddress');
  let minOrderAmount, minTransferAmount;
  console.log('bnbAddress', bnbAddress);
  console.log('usdtAddress', usdtAddress);

  // let a = await geniDexContract.getAllMarkets();
  // console.log(a)
  // return;
  let markets = await geniDexHelper.getAllMarkets();
  console.log('markets', markets);

  await listToken(ethers.ZeroAddress); // list ETH
  await listToken(geniTokenAddress)
  await listToken(bnbAddress)
  await listToken(arbAddress)
  await listToken(usdtAddress)
  await listToken(daiAddress)

  // GENI_USDT - 1
  await addMarket(geniTokenAddress, usdtAddress);

  // ETH_USDT - 2
  await addMarket(ethers.ZeroAddress, usdtAddress);

  // GENI_ETH - 3
  await addMarket(geniTokenAddress, ethers.ZeroAddress);

  // ARB_DAI - 4
  await addMarket(arbAddress, daiAddress);

  // ARB_ETH - 5
  await addMarket(arbAddress, ethers.ZeroAddress);

  // BNB_USDT - 6
  await addMarket(bnbAddress, usdtAddress);

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
  process.exit(0);

}

async function addMarket(baseToken, quoteToken){
  try{
    let tx = await adminSDK.addMarket({
      signer: owner,
      baseToken,
      quoteToken
    })
    await fn.printGasUsed(tx, 'addMarket');
  }catch(error){
    utils.logError(error)
  }
}

async function listToken(tokenAddress){
  let minTransferAmount = utils.parseBaseUnit("1");
  let minOrderAmount = utils.parseBaseUnit("10");
  try{
    let tx = await adminSDK.listToken({
      signer: owner,
      tokenAddress,
      minTransferAmount,
      minOrderAmount
    })
    await fn.printGasUsed(tx, 'listToken');
  }catch(error){
    utils.logError(error)
  }
}

main();