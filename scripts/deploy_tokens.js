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
    
    [contract, token] = await tokenHelper.deploy('GeniDex OP Token', 'gOP', 18);
    OPAddress = contract.target;
    data.set('opAddress', OPAddress);

    [contract, token] = await tokenHelper.deploy('GeniDex ARB Token', 'gARB', 18);
    data.set('arbAddress', contract.target);

    [contract, token] = await tokenHelper.deploy('GeniDex USDT Token', 'gUSDT', 6);
    USDTAddress = contract.target;
    data.set('usdtAddress', USDTAddress);

    [contract, token] = await tokenHelper.deploy('GeniDex DAI Token', 'gDAI', 18);
    DAIAddress = contract.target;
    data.set('daiAddress', DAIAddress);

    geniDexContract = await geniDexHelper.getContract();
    await geniDexContract.updateTokenIsUSD(USDTAddress, true);
    await geniDexContract.updateTokenIsUSD(DAIAddress, true);

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
