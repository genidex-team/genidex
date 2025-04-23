
const { ethers, upgrades, waffle, network } = require('hardhat');
const expect = require('chai').expect;

const data = require('../helpers/data');
const geniDexHelper = require('../helpers/genidex.h');
const fn = require('../helpers/functions');
// const helper = require('./helpers/eth_balances_helper');
const tokenWalletHelper = require('../helpers/token.wallet.h');
const ordersHelper = require('../helpers/orders.h');
const marketsHelper = require('../helpers/markets.h');
const Market = require('../helpers/market.h');

var geniDexContract;
var marketId = 1;
var market;// = marketsHelper.getMarket(marketId);
var initAmount = '1000.0';

async function main() {
    
    before(async ()=>{
        [deployer, trader1, trader2, feeReceiver] = await ethers.getSigners();
        console.log('trader1 - buyer:', trader1.address);
        console.log('trader2 - buyer:', trader2.address);
        // console.log('feeReceiver', feeReceiver.address);
        market = new Market(marketId);
        baseAddress = market.data.baseAddress;
        quoteAddress = market.data.quoteAddress;
        quoteDecimal = market.data.quoteDecimals;
        baseDecimal = market.data.baseDecimals;
        price = market.parsePrice(0.000025);
        quantity = market.parseQuantity(1);
        total = market.total(price, quantity);
    });

    describe('Trade', () => {
        it("Deployed", async ()=>{
            // geniDexContract = await geniDexHelper.deploy();
            geniDexContract = await geniDexHelper.upgrade();
            // geniDexContract = await geniDexHelper.getContract();
            geniDexAddress = geniDexContract.target;

            await geniDexHelper.init();
            await tokenWalletHelper.init();
            await ordersHelper.init();
        });

        it("Deposit", async ()=>{

            let gQuote1Balance = await tokenWalletHelper.getGeniDexBalance('trader1', quoteAddress, trader1, true);
            // if(gQuote1Balance=="0.0"){
                await tokenWalletHelper.deposit(quoteAddress, trader1, initAmount);
                await tokenWalletHelper.deposit(baseAddress, trader2, initAmount);

                // await tokenWalletHelper.getOnChainBalance(quoteAddress, trader1);
                await tokenWalletHelper.getGeniDexBalance('trader1', quoteAddress, trader1);
                
                // await tokenWalletHelper.getOnChainBalance(baseAddress, trader2);
                await tokenWalletHelper.getGeniDexBalance('trader2', baseAddress, trader2);
            // }
            
        });
        // return;
        it("Buy", async ()=>{
            // expect(await gQuote1Balance()).to.equal(initAmount);
            // expect(await gBase1Balance()).to.equal("0.0");
            // expect(await gQuote2Balance()).to.equal("0.0");
            // expect(await gBase2Balance()).to.equal(initAmount);

            console.log('buyOrders', await ordersHelper.getDescFormatBuyOrders(marketId) );
            console.log('sellOrders', await ordersHelper.getAscFormatSellOrders(marketId) );

            await testPlaceSellOrder();
            // await testPlaceBuyOrder();

            console.log('buyOrders', await ordersHelper.getDescFormatBuyOrders(marketId) );
            console.log('sellOrders', await ordersHelper.getAscFormatSellOrders(marketId) );

            return;
            /*
            await tokenWalletHelper.getGeniDexBalance('trader1', quoteAddress, trader1);

            // let buyOrders = await ordersHelper.getDescFormatBuyOrders(marketId);
            // console.log('buyOrders', buyOrders);
            // let sellOrders = await ordersHelper.getAscFormatSellOrders(marketId);
            // console.log('sellOrders', sellOrders);
            
            await testBuyOrder();
            await tokenWalletHelper.getGeniDexBalance('feeReceiver', quoteAddress, feeReceiver);
            // expect(await tokenWalletHelper.getGeniDexBalance('trader1', quoteAddress, trader1)).equal(0);
            // expect(await tokenWalletHelper.getGeniDexBalance('trader1', baseAddress, trader1)).equal(210);
            // expect(await tokenWalletHelper.getGeniDexBalance('trader2', baseAddress, trader2)).equal(0);
            // expect(await tokenWalletHelper.getGeniDexBalance('trader2', quoteAddress, trader2)).equal(721);

            buyOrders = await ordersHelper.getDescFormatBuyOrders(marketId);
            console.log('buyOrders', buyOrders);
            sellOrders = await ordersHelper.getAscFormatSellOrders(marketId);
            console.log('sellOrders', sellOrders);*/
            
        });
    });
}

async function testPlaceSellOrder(){
    let price = market.parsePrice(1);
    let quantity = market.parseQuantity(1);
    await buy(price, quantity);
    await buy(price, quantity);
    await buy(price, quantity);
    await buy(price, quantity);
    await buy(price, quantity);
    await buy(price, quantity);
    await buy(price, quantity);
    await buy(price, quantity);
    await buy(price, quantity);
    await buy(price, quantity);
    // console.log('sellOrders', await ordersHelper.getAscFormatSellOrders(marketId) );

    // await sell(3, 1);
    // await gQuote1Balance();
    quantity = market.parseQuantity(10);
    await sell(price, quantity);

    // match 0, old order index: 13.07 USD v
    // match 5, no order index: 18.03 USD v
    // match 0, new order index: 21.16 USD v
    // match 5, new order index: 34.03 USD v
    
    // expect(await gQuote1Balance()).to.equal(initAmount);
}

async function testPlaceBuyOrder(){

    let price = market.parsePrice(1);
    let quantity = market.parseQuantity(1);
    await sell(price, quantity);
    await sell(price, quantity);
    await sell(price, quantity);
    await sell(price, quantity);
    await sell(price, quantity);
    await sell(price, quantity);
    await sell(price, quantity);
    await sell(price, quantity);
    await sell(price, quantity);
    await sell(price, quantity);
    // console.log('sellOrders', await ordersHelper.getAscFormatSellOrders(marketId) );

    // await sell(3, 1);
    // await gQuote1Balance();
    quantity = market.parseQuantity(10);
    await buy(price, quantity);
    // await gQuote1Balance();
    // await cancelBuyOrder(0);
    // await gQuote1Balance();

    // match 0, old order index: 14.54 USD
    // match 5, no order index: 18.80 USD
    // match 0, new order index: 22.63 USD
    // match 5, new order index: 34.81 USD

    // await buy(3, 1);
    // console.log("===========");
    // await gBase2Balance();
    // await sell(3, 1);
    // await gBase2Balance();
    // await cancelSellOrder(0);
    // await gBase2Balance();
    // expect(await gQuote1Balance()).to.equal(initAmount);
}

async function testBuyOrder(){
    var price = 3.7;
    var quantity = 70;
    for(var i=0; i<6; i++){
        await sell((price -= 0.1).toFixed(6), (quantity -= 10).toFixed(6));
    }
    // await sell(2.9, 20);

    await buy(3.6, 210.0001);
    price = 3.0;
    quantity = 0;
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

async function cancelBuyOrder(orderIndex){
    await ordersHelper.cancelBuyOrder(trader1, marketId, orderIndex);
}

async function cancelSellOrder(orderIndex){
    await ordersHelper.cancelSellOrder(trader2, marketId, orderIndex);
}

async function gQuote1Balance(){
    return await tokenWalletHelper.getGeniDexBalance('trader1', quoteAddress, trader1, true);
}

async function gBase1Balance(){
    return await tokenWalletHelper.getGeniDexBalance('trader1', baseAddress, trader1, true);
}

async function gQuote2Balance(){
    return await tokenWalletHelper.getGeniDexBalance('trader2', quoteAddress, trader2, true);
}

async function gBase2Balance(){
    return await tokenWalletHelper.getGeniDexBalance('trader2', baseAddress, trader2, true);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});