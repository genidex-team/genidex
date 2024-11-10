// scripts/deploy_upgradeable_box.js
const { ethers, upgrades } = require('hardhat');
const hre = require("hardhat");
const fn = require('../helpers/functions');
const data = require('../helpers/data');
const geniDexHelper = require('../helpers/genidex.h');
const tokenHelper = require('../helpers/token.h');

async function main () {
    await geniDexHelper.init();
    await tokenHelper.init();

    var markets = await geniDexHelper.getAllMarkets();
    // console.log(markets);

    var tokenSet = new Set();
    for(var marketId in markets){
        console.log(marketId);
        let market = markets[marketId];
        tokenSet.add(market.baseAddress);
        tokenSet.add(market.quoteAddress);
    }
    var tokens = {};
    for(tokenAddress of tokenSet){
        console.log(tokenAddress);
        tokens[tokenAddress] = await tokenHelper.getTokenInfo(tokenAddress);
    }
    console.log('tokens', tokens);

}

main();