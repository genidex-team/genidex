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
let owner;

async function main () {

  await config.init();
  adminSDK = config.adminSDK;
  [owner] = await ethers.getSigners();

  // const geniDexContract = await geniDexHelper.upgrade();
  let geniTokenAddress = dataV2.getGeniTokenAddress(network.name)
  let bnbAddress = data.get('bnbAddress');
  let arbAddress = data.get('arbAddress');
  let usdtAddress = data.get('usdtAddress');
  let daiAddress = data.get('daiAddress');
  console.log('bnbAddress', bnbAddress);
  console.log('usdtAddress', usdtAddress);

  // let markets = await config.genidexSDK.markets.getAllMarkets();
  // console.log('markets', markets);

  await listToken(ethers.ZeroAddress); // list ETH
  await listToken(geniTokenAddress)
  await listToken(bnbAddress)
  await listToken(arbAddress)
  await listToken(usdtAddress)
  await listToken(daiAddress)

  process.exit();

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