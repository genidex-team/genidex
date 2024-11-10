
const { ethers, upgrades } = require('hardhat');
const expect = require('chai').expect;

const fn = require('../helpers/functions');
const data = require('../helpers/data');
const geniDexHelper = require('../helpers/genidex.h');
const tokenHelper = require('../helpers/token.h');

var geniDexAddress;
var geniDexContract;

var OPAddress;
var USDTAddress;
var rs;

async function main() {

    before(async ()=>{
        // OPContract = await tokenHelper.deploy('OP Token', 'OP', 18);
        // OPAddress = OPContract.target;
        // OPContract2 = await tokenHelper.deploy('OP Token2', 'OP2', 18);
        // OPAddress2 = OPContract2.target;
        // // OPContract = await ethers.getContractAt("TestToken", OPAddress);

        // USDTContract = await tokenHelper.deploy('USDT Token', 'USDT', 8);
        // USDTAddress = USDTContract.target;

        // [deployer, trader1, trader2] = await ethers.getSigners();
        // OPdecimals = await OPContract.decimals();
    });

    describe('Test Balances', function() {
        it("Deployed", async ()=>{
            // geniDexContract = await geniDexHelper.deploy();
            geniDexContract = await geniDexHelper.upgrade();
            geniDexAddress = geniDexContract.target;
        });
        
        it("addMarket", async ()=>{
            for(var i=0; i<1; i++){
                let baseToken = await tokenHelper.deployRandomBaseToken();
                let quoteToken = await tokenHelper.deployRandomQuoteToken();
                rs = await geniDexContract.addMarket(baseToken.address, quoteToken.address);
                console.log('\n', i, '. addMarket');
                fn.printGasUsed(rs, 'addMarket');
            }
            // rs = await geniDexContract.addMarket(OPAddress, USDTAddress);
            // fn.printGasUsed(rs, 'addMarket');
            // rs = await geniDexContract.addMarket(OPAddress2, USDTAddress);
            // fn.printGasUsed(rs, 'addMarket');
        });

        it("getAllMarkets", async ()=>{
            let markets = await geniDexHelper.getAllMarkets();
            console.log('markets.length', markets.length);
        });

        it("getAllTokens", async ()=>{
            let tokens = await geniDexHelper.getAllTokens();
            console.log('tokens.length', tokens.length);
        });
        

    });
    

    


}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});