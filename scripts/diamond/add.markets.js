// scripts/deploy_upgradeable_box.js
const { ethers, upgrades, network } = require('hardhat');
const fn = require('../../helpers/functions');
const data = require('../../helpers/data');
const dataV2 = require('geni_data');
const geniDexHelper = require('../../helpers/genidex.h')
const {utils} = require("genidex-sdk")
const {Admin} = require("genidex-sdk/admin")
const config = require('../../config/config');
let adminSDK;
let owner, upgrader, pauser, operator;

async function main () {

  await config.init();
  adminSDK = config.adminSDK;
  [owner, upgrader, pauser, operator] = await ethers.getSigners();

  // const geniDexContract = await geniDexHelper.upgrade();
  let geniTokenAddress = dataV2.getGeniTokenAddress(network.name)
  let bnbAddress = data.get('bnbAddress');
  let arbAddress = data.get('arbAddress');
  let usdtAddress = data.get('usdtAddress');
  let daiAddress = data.get('daiAddress');
  let minOrderAmount, minTransferAmount;
  console.log('bnbAddress', bnbAddress);
  console.log('usdtAddress', usdtAddress);

  // let markets = await config.genidexSDK.markets.getAllMarkets();
  // console.log('markets', markets);

  // GENI_USDT - 1
  await addMarket(geniTokenAddress, usdtAddress);
  await setMarketIsRewardable(1);

  // ETH_USDT - 2
  await addMarket(ethers.ZeroAddress, usdtAddress);
  await setMarketIsRewardable(2);

  // GENI_ETH - 3
  await addMarket(geniTokenAddress, ethers.ZeroAddress);
  await setMarketIsRewardable(3);

  // ARB_DAI - 4
  await addMarket(arbAddress, daiAddress);
  await setMarketIsRewardable(4);

  // ARB_ETH - 5
  await addMarket(arbAddress, ethers.ZeroAddress);
  await setMarketIsRewardable(5);

  // BNB_USDT - 6
  await addMarket(bnbAddress, usdtAddress);
  await setMarketIsRewardable(6);

  // await geniDexContract.updateTokenIsUSD(usdtAddress, true);
  // await geniDexContract.updateTokenIsUSD(daiAddress, true);

  // await geniDexContract.updateMarketIsRewardable(1, true);
  // await geniDexContract.updateMarketIsRewardable(2, true);
  // await geniDexContract.updateMarketIsRewardable(3, true);
  // await geniDexContract.updateMarketIsRewardable(4, true);
  // await geniDexContract.updateMarketIsRewardable(5, true);

  // await geniDexContract.updateUSDMarketID(ethers.ZeroAddress, 2);

  markets = await config.genidexSDK.markets.getAllMarkets();
  console.log('markets', markets);
  process.exit(0);

}

async function addMarket(baseToken, quoteToken){
  return;
  try{
    let tx = await adminSDK.addMarket({
      signer: operator,
      baseToken,
      quoteToken
    })
    await fn.printGasUsed(tx, 'addMarket');
  }catch(error){
    utils.logError(error)
  }
}

async function setMarketIsRewardable(marketId){
  return await adminSDK.updateMarketIsRewardable({signer: operator, marketId: marketId, isRewardable: true})
}


main();