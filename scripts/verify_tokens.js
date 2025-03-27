// await hre.ethers.deployContract("Lock", [unlockTime]

const { ethers, network } = require('hardhat');
const helpers = require("@nomicfoundation/hardhat-network-helpers");
const data = require('../helpers/data');
const tokenHelper = require('../helpers/tokens.h');
const geniDexHelper = require('../helpers/genidex.h');

var owner;
var trader1 = '';
var trader2 = '';
var OPAddress, USDTAddress, DAIAddress;

async function main() {
    
    await tokenHelper.verify(data.get('opAddress'), 'GeniDex OP Token', 'gOP', 18);
    await tokenHelper.verify(data.get('arbAddress'), 'GeniDex ARB Token', 'gARB', 18);
    await tokenHelper.verify(data.get('usdtAddress'), 'GeniDex USDT Token', 'gUSDT', 6);
    await tokenHelper.verify(data.get('daiAddress'), 'GeniDex DAI Token', 'gDAI', 18);

    console.log(network.name);
    // if(network.name=='sepolia'){
    //     await tokenHelper.verify(OPAddress, 'GeniDex OP Token', 'gOP', 18);
    //     await tokenHelper.verify(USDTAddress, 'GeniDex USDT Token', 'gUSDT', 6);
    // }
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
