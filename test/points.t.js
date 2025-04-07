
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
const pointsHelper = require('../helpers/points.h');


var geniDexContract;
var marketId;
var market;
var price, quantity, total;

async function main() {

    before(async ()=>{
        [deployer, trader1, trader2, feeReceiver] = await ethers.getSigners();
        // console.log('feeReceiver', feeReceiver.address);
        marketId = 1;
        market = new Market(marketId);
        // console.log(market);
        price = market.parsePrice('2500');
        quantity = market.parseQuantity('1');
        total = market.total(price, quantity);
        geniDexHelper.init();
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

        it("PlaceBuyOrder - Fully Filled Orders", async ()=>{
            // return;
            console.log("\n\n============ PlaceBuyOrder - Fully Filled Orders ============");

            var points1 = await gPoints1();
            var points2 = await gPoints2();
            // return;
            await ordersHelper.cancelAllBuyOrder(marketId);
            await ordersHelper.cancelAllSellOrder(marketId);

            var sellPrice = price;// - price/10n; // -10%
            await sell(sellPrice, quantity);
            console.log(price, quantity)
            await buy(price, quantity);

            total = market.total(sellPrice, quantity);
            let points = await market.toPoints(total);
            console.log(
                formatPoint(points1), '+',
                formatPoint(points), '=',
                formatPoint(await gPoints1())
            );
            expect(points1 + points).to.equal(await gPoints1());
            expect(points2).to.equal(await gPoints2());

            console.log('============\n\n');
        });

        // return;
        it("PlaceSellOrder - Fully Filled Orders", async ()=>{
            // return;
            console.log("\n\n============ PlaceSellOrder - Fully Filled Orders ============");

            await ordersHelper.cancelAllBuyOrder(marketId);
            await ordersHelper.cancelAllSellOrder(marketId);
            let points1 = await gPoints1();
            let points2 = await gPoints2();

            var buyPrice = price;// + price/10n; // -10%
            await buy(buyPrice, quantity);
            await sell(price, quantity);

            total = market.total(buyPrice, quantity);
            let points = await market.toPoints(total);
            console.log(
                formatPoint(points2), '+',
                formatPoint(points), '=',
                formatPoint(await gPoints2())
            );
            expect(points1).to.equal(await gPoints1());
            expect(points2 + points).to.equal(await gPoints2());

            console.log('============\n\n');
        })

    });
}

async function gPoints1(){
    let point = await pointsHelper.getPoints(trader1);
    console.log('trader1\'s points', formatPoint(point));
    return point;
}

async function gPoints2(){
    let point = await pointsHelper.getPoints(trader2);
    console.log('trader2\'s points', formatPoint(point));
    return point;
}

function formatPoint(points){
    return (pointsHelper.format(points));
}

async function buy(price, quantity){
    return await ordersHelper.placeBuyOrder(trader1, marketId, price, quantity);
}

async function sell(price, quantity){
    return await ordersHelper.placeSellOrder(trader2, marketId, price, quantity);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});