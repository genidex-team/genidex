
const { ethers, upgrades, waffle, network } = require('hardhat');
const expect = require('chai').expect;

const data = require('../helpers/data');
const geniDexHelper = require('../helpers/genidex.h');
const tokenHelper = require('../helpers/token.h');
const fn = require('../helpers/functions');
// const helper = require('./helpers/eth_balances_helper');
const tokenWalletHelper = require('../helpers/token.wallet.h');
const ordersHelper = require('../helpers/orders.h');
const markets = require('../helpers/markets.h');

var geniDexContract;
var marketId = 1;


async function main() {
    const geniDexAddress = data.get('geniDexAddress');
    console.log(geniDexAddress);
    // geniDexContract = await geniDexHelper.getContract();
    [deployer, trader1, trader2] = await ethers.getSigners();
    await ordersHelper.init();
    await tokenWalletHelper.init();
    const market = markets.getMarket(marketId);
    console.log(market);
    let { baseAddress, quoteAddress } = market;
    console.log(baseAddress, quoteAddress);
    // await tokenWalletHelper.deposit(quoteAddress, trader1, '15000');
    // await tokenWalletHelper.deposit(baseAddress, trader2, '15000');
    testBuyOrder();
}

async function testBuyOrder(){
    var price = 3.7;
    var quantity = 70;
    for(var i=0; i<6; i++){
        await sell((price -= 0.1).toFixed(6), (quantity -= 10).toFixed(6));
    }
    // await sell(2.9, 20);

    // await buy(3.6, 210.0001);
    // price = 3.0;
    // quantity = 0;
    // for(var i=0; i<5; i++){
    //     await buy((price += 0.1).toFixed(6), (quantity += 10).toFixed(6));
    // }

    // price = 3.7;
    // quantity = 70;
    // for(var i=0; i<6; i++){
    //     await sell((price -= 0.1).toFixed(6), (quantity -= 10).toFixed(6));
    // }
    
}

async function buy(price, quantity){
    await ordersHelper.placeBuyOrder(trader1, marketId, price, quantity);
}

async function sell(price, quantity){
    await ordersHelper.placeSellOrder(trader2, marketId, price, quantity);
}


main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

setTimeout(() => {
    console.log('Script will exit after 1 hour');
}, 3600000);