

const { ethers, upgrades, waffle, network } = require('hardhat');
const data = require('../helpers/data');
const geniDexHelper = require('../helpers/genidex.h');

var geniDexContract;

async function main() {

    [deployer, trader1, trader2, feeReceiver] = await ethers.getSigners();
    // console.log('feeReceiver', feeReceiver.address);
    baseAddress = data.get('opAddress');
    quoteAddress = data.get('usdtAddress');
    // geniDexContract = await geniDexHelper.upgrade();
    geniDexContract = await geniDexHelper.getContract();

    geniDexContract.on('OnPlaceBuyOrder', (marketId, trader, orderIndex, price, quantity, remainingQuantity, event) => {
        console.log('Event:', event);
        console.log('Arguments:', marketId, trader, orderIndex, price, quantity, remainingQuantity);
    });

    geniDexContract.on('OnPlaceSellOrder', (marketId, trader, orderIndex, price, quantity, remainingQuantity, event) => {
        console.log('Event:', event);
        console.log('Arguments:', marketId, trader, orderIndex, price, quantity, remainingQuantity);
    });

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});