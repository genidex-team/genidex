
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
const pointsHelper = require('../helpers/points.h');
const {utils, constants} = require('genidex-sdk')
const config = require('../config/config');
const sdk = config.genidexSDK;

var geniDexContract;
var marketId;
var market;
var price, quantity, total;

async function main() {

    before(async ()=>{
        [deployer, upgrader, pauser, operator,  trader1, trader2, feeReceiver] = await ethers.getSigners();
        // console.log('feeReceiver', feeReceiver.address);
        marketId = 3;
        // console.log(market);
        price = utils.parseBaseUnit('0.5');
        quantity = utils.parseBaseUnit('200');
        total = utils.total(price, quantity);
        geniDexHelper.init();
        market = await sdk.markets.getMarket(marketId);
    });

    describe('Trade', () => {
        it("Deployed", async ()=>{
            // geniDexContract = await geniDexHelper.deploy();
            // geniDexContract = await geniDexHelper.upgrade();
            // geniDexContract = await geniDexHelper.getContract();
            // geniDexAddress = geniDexContract.target;
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

            total = utils.total(sellPrice, quantity);
            let points = await toPoints(total);
            console.log(
                formatPoint(points1), '+',
                formatPoint(points), '=',
                formatPoint(await gPoints1())
            );
            console.log('==================', points1, points)
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

            total = utils.total(buyPrice, quantity);
            let points = await toPoints(total);
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

async function toPoints(amount){
    let quoteAddress = market.quoteAddress;
    let quoteToken = await sdk.tokens.getTokenInfo(quoteAddress);
    // console.log(quoteToken)
    let points = 0n;
    if(market.isRewardable!=true) return 0n;

    if(quoteToken.isUSD == true){
        points = amount;
    }else if(quoteToken.usdMarketID > 0){
        let usdMarket = await sdk.markets.getMarket(quoteToken.usdMarketID); //markets.getMarket(quoteToken.usdMarketID);
        points = usdMarket.price * amount / constants.BASE_UNIT;
    }
    return points;
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