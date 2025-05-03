
const { ethers, upgrades, waffle } = require('hardhat');
const expect = require('chai').expect;

const data = require('../helpers/data');
const geniDexHelper = require('../helpers/genidex.h');
const tokenHelper = require('../helpers/tokens.h');
const fn = require('../helpers/functions');
const EthWalletHelper = require('../helpers/eth.wallet.h');

var geniDexContract;

var walletBalance, geniDexBalance;
var amount, ethAmount;



async function main() {

    before(async ()=>{
        [deployer, trader1, trader2] = await ethers.getSigners();
        wallet1 = new EthWalletHelper(trader1);
        wallet2 = new EthWalletHelper(trader2);
    });

    describe('Test Balances', () => {
        it("Deployed", async ()=>{
            // geniDexContract = await geniDexHelper.deploy();
            geniDexContract = await geniDexHelper.upgrade();
            geniDexAddress = geniDexContract.target;
            await wallet1.init();
            await wallet2.init();
        });

        it("Balances", async ()=>{

            expect(wallet1.walletBalance).to.equal(await wallet1.getWalletBalance());
            expect(wallet1.geniDexBalance).to.equal(await wallet1.getGeniDexBalance());

            // expect(wallet2.walletBalance).to.equal(await wallet2.getWalletBalance());
            // expect(wallet2.geniDexBalance).to.equal(await wallet2.getGeniDexBalance());

            await wallet1.deposit("10");
            expect(wallet1.walletBalance).to.equal(await wallet1.getWalletBalance());
            expect(wallet1.geniDexBalance).to.equal(await wallet1.getGeniDexBalance());

            // await wallet2.deposit("10");
            // expect(wallet2.walletBalance).to.equal(await wallet2.getWalletBalance());
            // expect(wallet2.geniDexBalance).to.equal(await wallet2.getGeniDexBalance());

            await wallet1.withdraw("1");
            expect(wallet1.walletBalance).to.equal(await wallet1.getWalletBalance());
            expect(wallet1.geniDexBalance).to.equal(await wallet1.getGeniDexBalance());

        });

    });
    
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});