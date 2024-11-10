
const { ethers, upgrades, waffle } = require('hardhat');
const expect = require('chai').expect;

const data = require('../helpers/data');
const geniDexHelper = require('../helpers/genidex.h');
const tokenHelper = require('../helpers/tokens.h');
const fn = require('../helpers/functions');
const EthWalletHelper = require('../helpers/eth.wallet.h');

var geniDexContract;

var onChainBalance, geniDexBalance;
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

            expect(wallet1.onChainBalance).to.equal(await wallet1.getOnChainBalance());
            expect(wallet1.geniDexBalance).to.equal(await wallet1.getGeniDexBalance());

            expect(wallet2.onChainBalance).to.equal(await wallet2.getOnChainBalance());
            expect(wallet2.geniDexBalance).to.equal(await wallet2.getGeniDexBalance());

            await wallet1.deposit("10");
            expect(wallet1.onChainBalance).to.equal(await wallet1.getOnChainBalance());
            expect(wallet1.geniDexBalance).to.equal(await wallet1.getGeniDexBalance());

            await wallet2.deposit("10");
            expect(wallet2.onChainBalance).to.equal(await wallet2.getOnChainBalance());
            expect(wallet2.geniDexBalance).to.equal(await wallet2.getGeniDexBalance());

            return;

            await helper.deposit("0.01");
            await helper.withdraw("0.01");
            expect(helper.onChainBalance).to.equal(await helper.getOnChainBalance());
            expect(helper.geniDexBalance).to.equal(await helper.getGeniDexBalance());

            await helper.withdraw("10");
            expect(helper.onChainBalance).to.equal(await helper.getOnChainBalance());
            expect(helper.geniDexBalance).to.equal(await helper.getGeniDexBalance());

            // await helper.deposit("1000");
            // await helper.batchWithdraw(1000, "1");
            
        });

    });
    
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});