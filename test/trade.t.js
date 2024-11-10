
const { ethers, upgrades, waffle, network } = require('hardhat');
const expect = require('chai').expect;

const data = require('../helpers/data');
const geniDexHelper = require('../helpers/genidex.h');
const tokenHelper = require('../helpers/tokens.h');
const fn = require('../helpers/functions');
// const helper = require('./helpers/eth_balances_helper');
const tokenWalletHelper = require('../helpers/token.wallet.h');
const EthWalletHelper = require('../helpers/eth.wallet.h');
const ordersHelper = require('../helpers/orders.h');
const Market = require('../helpers/market.h');


var geniDexContract;
var marketId = 1;
var market;
var baseDecimal;

var quote1Balance, quote2Balance, base1Balance, base2Balance;
var price, quantity, total;
var baseAddress, quoteAddress;

async function main() {
    
    before(async ()=>{
        [deployer, trader1, trader2, feeReceiver] = await ethers.getSigners();
        // console.log('feeReceiver', feeReceiver.address);
        market = new Market(marketId);
        // console.log(market);
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
            await tokenWalletHelper.init();
            await ordersHelper.init();
        });

        it("Deposit", async ()=>{
            let gQuote1Balance = await tokenWalletHelper.getGeniDexBalance('trader1', quoteAddress, trader1, true);
            // if(gQuote1Balance=="0.0"){
                await tokenWalletHelper.deposit(quoteAddress, trader1, '1000');
                await tokenWalletHelper.deposit(baseAddress, trader2, '1000');
                // console.log(baseAddress);
                await tokenWalletHelper.getOnChainBalance('trader1', baseAddress, trader1);
                await tokenWalletHelper.getGeniDexBalance('trader1', baseAddress, trader1);

                await tokenWalletHelper.getOnChainBalance('trader1', quoteAddress, trader1);
                await tokenWalletHelper.getGeniDexBalance('trader1', quoteAddress, trader1);
            // }
        });

        it("PlaceBuyOrder - Unfilled Orders", async ()=>{
            return;
            console.log("\n\n============ PlaceBuyOrder - Unfilled Orders ============");

            await ordersHelper.cancelAllBuyOrder(marketId);
            await ordersHelper.cancelAllSellOrder(marketId);

            quote1Balance = await gQuote1Balance();
            base1Balance = await gBase1Balance();
            await buy(price, quantity);
            console.log('buyOrders', await ordersHelper.getDescFormatBuyOrders(marketId));
            console.log('sellOrders', await ordersHelper.getAscFormatSellOrders(marketId));
            
            total = market.total(price, quantity);

            // console.log(await gQuote1Balance(), quote1Balance, total, calcFee(total));
            // process.exit();

            expect(await gQuote1Balance()).to.equal(quote1Balance - total - calcFee(total));
            expect(await gBase1Balance()).to.equal(base1Balance);
            console.log('============\n\n');
        });

        it("PlaceBuyOrder - Fully Filled Orders", async ()=>{
            // return;
            console.log("\n\n============ PlaceBuyOrder - Fully Filled Orders ============");

            await ordersHelper.cancelAllBuyOrder(marketId);
            await ordersHelper.cancelAllSellOrder(marketId);

            quote1Balance = await gQuote1Balance();
            base1Balance = await gBase1Balance();
            quote2Balance = await gQuote2Balance();
            base2Balance = await gBase2Balance();

            var sellPrice = price - price/10n; // -10%
            await sell(sellPrice, quantity);
            await buy(price, quantity);
            console.log('buyOrders', await ordersHelper.getDescFormatBuyOrders(marketId));
            console.log('sellOrders', await ordersHelper.getAscFormatSellOrders(marketId));

            var totalValue = sellPrice * quantity;
            // console.log(await gQuote1Balance(), quote1Balance, totalValue*(1+fee));
            // process.exit();
            total = market.total(sellPrice, quantity);
            expect(await gQuote1Balance()).to.equal(quote1Balance - total - calcFee(total));
            expect(await gBase1Balance()).to.equal(base1Balance + quantity );

            total = market.total(sellPrice, quantity);
            expect(await gQuote2Balance()).to.equal(quote2Balance + total - calcFee(total));
            expect(await gBase2Balance()).to.equal(base2Balance - quantity );
            console.log('============\n\n');
        });
        return;
        it("PlaceBuyOrder - Partially Filled Orders", async ()=>{
            // return;
            console.log("\n\n============ PlaceBuyOrder - Partially Filled Orders ============");

            await ordersHelper.cancelAllBuyOrder(marketId);
            await ordersHelper.cancelAllSellOrder(marketId);

            quote1Balance = await gQuote1Balance();
            base1Balance = await gBase1Balance();
            quote2Balance = await gQuote2Balance();
            base2Balance = await gBase2Balance();

            var sellPrice = price - price/10n; // -10%
            var sellQuantity = quantity - quantity/2n; // -50%
            // console.log(sellPrice, sellQuantity); return;
            await sell(sellPrice, sellQuantity);
            const orderIndex = await buy(price, quantity);
            console.log('buyOrders', await ordersHelper.getDescFormatBuyOrders(marketId));
            console.log('sellOrders', await ordersHelper.getAscFormatSellOrders(marketId));


            // var remainingQuantity = quantity - sellQuantity;
            // var tradeValue = sellPrice * sellQuantity;
            // var remainingValue = remainingQuantity * price;
            // var totalValue = tradeValue + remainingValue;
            var remainingQuantity = quantity - sellQuantity;
            var tradeValue = market.total(sellPrice, sellQuantity);
            var remainingValue = market.total(price, remainingQuantity);
            var totalValue = tradeValue + remainingValue;

            // total = market.total(price, quantity);
            // console.log(quantity, sellQuantity);
            // console.log(tradeValue, remainingValue, remainingQuantity);
            // console.log(await gQuote1Balance(), quote1Balance, totalValue, calcFee(totalValue));
            // process.exit();
            expect(await gQuote1Balance()).to.equal(quote1Balance - totalValue - calcFee(totalValue));
            expect(await gBase1Balance()).to.equal(base1Balance + sellQuantity );

            expect(await gQuote2Balance()).to.equal(quote2Balance + tradeValue - calcFee(tradeValue));
            expect(await gBase2Balance()).to.equal(base2Balance - sellQuantity );
        });

        it("cancelBuyOrder - Unfilled Orders", async ()=>{
            // return;
            console.log('\n============ cancelBuyOrder - Unfilled Orders ============');
            await ordersHelper.cancelAllBuyOrder(marketId);
            await ordersHelper.cancelAllSellOrder(marketId);

            const orderIndex = await buy(price, quantity);

            quote1Balance = await gQuote1Balance();
            base1Balance = await gBase1Balance();

            await cancelBuyOrder(orderIndex);
            console.log('orderIndex', orderIndex);
            total = market.total(price, quantity);
            expect(await gQuote1Balance()).to.equal(quote1Balance + total + calcFee(total));
            expect(await gBase1Balance()).to.equal(base1Balance);
        });

        it("cancelBuyOrder - Partially Filled Orders", async ()=>{
            // return;
            console.log('\n============ cancelBuyOrder - Partially Filled Orders ============');
            await ordersHelper.cancelAllBuyOrder(marketId);
            await ordersHelper.cancelAllSellOrder(marketId);

            var sellPrice = price;
            var sellQuantity = quantity - quantity/2n; // -50%
            await sell(sellPrice, sellQuantity);
            const orderIndex = await buy(price, quantity);

            // var tradeValue = sellPrice * sellQuantity;
            var remainingQuantity = quantity - sellQuantity;
            var remainingValue = market.total(price, remainingQuantity)
            // var totalValue = tradeValue + remainingValue;

            quote1Balance = await gQuote1Balance();
            base1Balance = await gBase1Balance();

            await cancelBuyOrder(orderIndex);
            console.log('orderIndex', orderIndex);

            expect(await gQuote1Balance()).to.equal(quote1Balance + remainingValue + calcFee(remainingValue));
            expect(await gBase1Balance()).to.equal(base1Balance);
        });

    });
}

async function buy(price, quantity){
    return await ordersHelper.placeBuyOrder(trader1, marketId, price, quantity);
}

async function sell(price, quantity){
    return await ordersHelper.placeSellOrder(trader2, marketId, price, quantity);
}

async function cancelBuyOrder(orderIndex){
    await ordersHelper.cancelBuyOrder(trader1, marketId, orderIndex);
}

async function gQuote1Balance(){
    return await tokenWalletHelper.getGeniDexBalance('trader1', quoteAddress, trader1);
}

async function gBase1Balance(){
    return await tokenWalletHelper.getGeniDexBalance('trader1', baseAddress, trader1);
}

async function gQuote2Balance(){
    return await tokenWalletHelper.getGeniDexBalance('trader2', quoteAddress, trader2);
}

async function gBase2Balance(){
    return await tokenWalletHelper.getGeniDexBalance('trader2', baseAddress, trader2);
}

async function gQuoteFeeBalance(){
    return await tokenWalletHelper.getGeniDexBalance('feeReceiver', quoteAddress, feeReceiver);
}

async function gBaseFeeBalance(){
    return await tokenWalletHelper.getGeniDexBalance('feeReceiver', baseAddress, feeReceiver);
}

function subQuantity(_quantity1, _quantity2){
    let quantity1 = ethers.parseUnits(_quantity1.toFixed(baseDecimal), baseDecimal);
    let quantity2 = ethers.parseUnits(_quantity2.toFixed(baseDecimal), baseDecimal);
    return quantity1 - quantity2;
}

// function market.total(_price, _quantity){
//     let price = ethers.parseUnits(_price.toFixed(market.priceDecimals), market.priceDecimals);
//     let quantity = ethers.parseUnits(_quantity.toFixed(baseDecimal), baseDecimal);
//     // console.log(price, quantity, price*quantity);
//     return price * quantity / ethers.parseUnits('1', market.marketDecimals);
// }

function calcFee(total){
    return total / 1000n;
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});