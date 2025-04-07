
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
var marketId = 1;
var market;
var baseDecimal;

var quote1Balance, quote2Balance, base1Balance, base2Balance;
var price, quantity, total;
var baseAddress, quoteAddress;

async function main() {
    
    before(async ()=>{
        [deployer, trader1, trader2, feeReceiver] = await ethers.getSigners();
        wallet1 = new EthWalletHelper(trader1);
        wallet2 = new EthWalletHelper(trader2);
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

        it("Widthdraw", async ()=>{
            var tokens = tokenHelper.tokens;
            console.log('tokens', tokens);
            for(var i in tokens){
                var token = tokens[i];
                var {address} = token;

                // process.exit();
                let balance1 = await gBalance1(address);
                let balance2 = await gBalance2(address);
                let amount = '1';
                await tokenWalletHelper.widthdraw(address, trader1, amount);
                await tokenWalletHelper.widthdraw(address, trader2, amount);

                expect(balance1 - ethers.parseUnits(amount, token.decimals))
                    .to.equal(await gBalance1(address));

                expect(balance2 - ethers.parseUnits(amount, token.decimals))
                    .to.equal(await gBalance2(address));
            }
        });

    });
}

async function depositETH(account, amount){
    let wallet1 = new EthWalletHelper(account);
    await wallet1.init();
    await wallet1.deposit(amount);
}

async function gBalance1(address){
    return await tokenWalletHelper.getGeniDexBalance('trader1', address, trader1);
}

async function gBalance2(address){
    return await tokenWalletHelper.getGeniDexBalance('trader2', address, trader2);
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
    return parseFloat(pointsHelper.format(points));
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

function calcFee(total){
    return total / 1000n;
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});