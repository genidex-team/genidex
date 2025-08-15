
const expect = require('chai').expect;
const { ethers, upgrades, waffle } = require('hardhat');
const geniDexHelper = require('./genidex.h');
const fn = require('./functions');
const config = require('../config/config');
const {utils} = require('genidex-sdk');

const provider = ethers.provider;
// var deployer, trader1, trader2;
var geniDexContract;

class EthWalletHelper{

    totalFee = 0n;
    geniDexContract;
    walletBalance;
    geniDexBalance;
    account;
    address;

    constructor(_account){
        this.account = _account;
    }

    async init(){
        this.address = await this.account.getAddress();
        this.geniDexContract = await geniDexHelper.getContract();
        // [deployer, trader1, trader2] = await ethers.getSigners();
        this.walletBalance = await this.getWalletBalance();
        this.geniDexBalance = await this.getGeniDexBalance();
    }

    addWeiFee(fee){
        // const normFee = utils.convertDecimals(fee, 18, 8);
        this.totalFee += fee;
        this.walletBalance -= fee;
    }

    async deposit(amount){
        // var _amount = ethers.parseEther(amount);
        // let transaction = await this.geniDexContract.connect(this.account).depositEth({value: _amount});
        var normAmount = utils.parseBaseUnit(amount);
        let transaction = await config.genidexSDK.balances.depositEth({
            signer: this.account,
            normAmount: normAmount
        })
        fn.printGasUsed(transaction, '\ndeposit '+amount+' ETH');
        let weiFee = await this.getWeiFee(transaction);
        // console.log('_amount', _amount);
        // console.log('weiFee', weiFee);
        // console.log(`walletBalance: ${this.walletBalance} - ${_amount} - ${weiFee} = `);
        this.addWeiFee(weiFee);
        this.walletBalance -= utils.convertDecimals(normAmount, 8, 18);
        this.geniDexBalance += utils.convertDecimals(normAmount, 8, 18);
        // console.log(`walletBalance: ${this.walletBalance}`);
    }

    async getWeiFee(transaction){
        const transactionReceipt = await transaction.wait();
        // const {maxPriorityFeePerGas} = transaction;
        const {gasUsed, gasPrice} = transactionReceipt;
        // console.log('transaction', transaction);
        // console.log('transactionReceipt', transactionReceipt);
        // const block = await provider.getBlock(transaction.blockNumber);
        // console.log('block.baseFeePerGas', block.baseFeePerGas)
        // console.log(transactionReceipt);
        // const l1Fee = await this.getL1Fee(transactionReceipt.hash);
        // console.log('l1Fee', l1Fee)
        return gasPrice * gasUsed;
    }

    async withdraw(amount){
        // let _amount = ethers.parseEther(amount);
        // let transaction = await this.geniDexContract.connect(this.account).withdrawEth(_amount);
        
        var normAmount = utils.parseBaseUnit(amount);
        let transaction = await config.genidexSDK.balances.withdrawEth({
            signer: this.account,
            normAmount: normAmount
        })

        fn.printGasUsed(transaction, '\nwithdraw '+amount+' ETH');
        let weiFee = await fn.getWeiFee(transaction);
        this.addWeiFee(weiFee);
        await transaction.wait();
        this.walletBalance += utils.convertDecimals(normAmount, 8, 18);
        this.geniDexBalance -= utils.convertDecimals(normAmount, 8, 18);
    }

    async checkwalletBalance(){
        return this.walletBalance == await this.getWalletBalance();
    }

    async batchWithdraw(n, amount){
        return new Promise((resolve, reject) =>{
            var count = 0;
            for(var i=0; i<n; i++){
                this.withdraw(amount).then(()=>{
                    count++;
                    if(count==n){
                        resolve(true);
                    }
                })
            }
        })
    }

    async getWalletBalance(){
        const rawBalance = await provider.getBalance(this.account);
        // const normBalance = await utils.getETHBalanceInBaseUnit(provider, this.address);
        console.log('getWalletBalance', ethers.formatEther(rawBalance).yellow);
        return rawBalance;
    }

    async getGeniDexBalance(){
        const normBalance = await config.genidexSDK.balances.getETHBalance(this.address)
        console.log('getGeniDexBalance', utils.formatBaseUnit(normBalance).yellow);
        return utils.convertDecimals(normBalance, 8, 18);
    }

    async getEthBalance(){
        const rawBalance = await provider.getBalance(this.account);
        // const normBalance = await utils.getETHBalanceInBaseUnit(provider, this.address);
        return ethers.formatEther(rawBalance);
    }

    async checkBalance1(amount){
        const ethBalance = await provider.getBalance(this.account);
        let balance = ethBalance + this.totalFee;
        balance = ethers.formatEther(balance);
        console.log('\n'+balance, '== ', amount);
        expect(balance).to.equal(amount);
    }

    async checkInAppBalance1(amount){
        let rs = await this.geniDexContract.connect(this.account).getEthBalance();
        let balance = ethers.formatEther(rs);
        console.log('\n'+balance, '== ', amount);
        expect(balance).to.equal(amount);
    }

}

module.exports = EthWalletHelper;