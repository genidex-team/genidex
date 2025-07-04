
const { ethers, upgrades } = require('hardhat');
const expect = require('chai').expect;

const {utils} = require('genidex-sdk');
const config = require('../config/config')
const data = require('../helpers/data');
const geniDexHelper = require('../helpers/genidex.h');
const tokenHelper = require('../helpers/tokens.h');
const fn = require('../helpers/functions');

var genidex;
var geniDexAddress;
var geniDexContract;

var tokenAddress;
var USDTAddress;
var rs;
var transaction;

async function main() {

    before(async ()=>{
        await config.init();
        genidex = config.genidex;

        // [OPContract, token] = await tokenHelper.deploy('OP Token', 'OP', 4);
        // OPAddress = OPContract.target;
        // OPContract = await ethers.getContractAt("TestToken", OPAddress);

        [deployer, trader1, trader2] = await ethers.getSigners();
        // OPdecimals = await OPContract.decimals();
        const tokens = await genidex.tokens.getAllTokens();
        tokenAddress = tokens[0];
    });

    describe('Test Balances', () => {
        it("Deployed", async ()=>{
            // geniDexContract = await geniDexHelper.deploy();
            geniDexContract = await geniDexHelper.upgrade();
            // geniDexContract = await geniDexHelper.getContract();
            geniDexAddress = geniDexContract.target;
        });
        //
        it("The OP balance of trader1 before depositing", async ()=>{
            // rs = await OPContract.balanceOf(trader1);
            // let balance = ethers.formatUnits(rs, OPdecimals);
            // console.log(balance);
            // expect(balance).to.equal("1000.0");
        });

        it("Deposit", async ()=>{
            var amount = ethers.parseUnits("0", 18);
            console.log('tokenAddress', tokenAddress);
            transaction = await genidex.balances.depositToken({
                signer: trader1,
                tokenAddress: tokenAddress,
                normAmount: amount,
                normApproveAmount: amount
            })
            // .catch(error=>console.error(error.message))
            // .catch(error=>utils.logError(error))
            await fn.printGasUsed(transaction, 'deposit');
            return;
            transaction = await OPContract.connect(trader1).approve(geniDexAddress, amount*2n);
            await fn.printGasUsed(transaction, 'approve');
            transaction = await geniDexContract.connect(trader1).depositToken(OPAddress, amount);
            await fn.printGasUsed(transaction, 'deposit');
            transaction = await geniDexContract.connect(trader1).depositToken(OPAddress, amount);
            await fn.printGasUsed(transaction, 'deposit');

            return;
            // await OPContract.connect(trader1).approve(geniDexAddress, amount);
            // transaction = await geniDexContract.connect(trader1).deposit(OPAddress, amount);
            // fn.printGasUsed(transaction, 'deposit');

            // await OPContract.connect(trader1).approve(geniDexAddress, amount);
            // transaction = await geniDexContract.connect(trader1).depositWithEvent(OPAddress, amount);
            // fn.printGasUsed(transaction, 'depositWithEvent');
        });
        return;
        it("The OP balance of trader1 after depositing", async ()=>{
            rs = await OPContract.balanceOf(trader1);
            let balance = ethers.formatUnits(rs, OPdecimals);
            console.log(balance, '== 990.0');
            // expect(balance).to.equal("990.0");
        });
        // return;
        it("The OP balance of trader1 on the exchange", async ()=>{
            rs = await geniDexContract.connect(trader1).getTokenBalance(OPAddress);
            let balance = ethers.formatUnits(rs, OPdecimals);
            console.log(balance, '== 10.0');
            expect(balance).to.equal("10.0");
        });

        it("Trader1 withdraw", async ()=>{
            let amount = ethers.parseUnits('10', OPdecimals);
            rs = await geniDexContract.connect(trader1).withdrawToken(OPAddress, amount);
        });

        it("The OP balance of trader1 after withdrawing", async ()=>{
            rs = await OPContract.balanceOf(trader1);
            let balance = ethers.formatUnits(rs, OPdecimals);
            console.log(balance, '== 1000.0');
            expect(balance).to.equal("1000.0");
        });

        it("The OP balance of trader1 on the exchange after withdrawing", async ()=>{
            rs = await geniDexContract.connect(trader1).getTokenBalance(OPAddress);
            let balance = ethers.formatUnits(rs, OPdecimals);
            console.log(balance, '== 0.0');
            expect(balance).to.equal("0.0");
        });

        //

    });
    

    


}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});