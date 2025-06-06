
const expect = require('chai').expect;
const { ethers, upgrades, waffle } = require('hardhat');
const geniDexHelper = require('./genidex.h');
const fn = require('./functions');

const provider = ethers.provider;
// var deployer, trader1, trader2;
var geniDexContract;

class EthWalletHelper{

    totalFee = 0n;
    geniDexContract;
    walletBalance;
    geniDexBalance;
    account;

    constructor(_account){
        this.account = _account;
    }

    async init(){
        this.geniDexContract = await geniDexHelper.getContract();
        // [deployer, trader1, trader2] = await ethers.getSigners();
        this.walletBalance = await this.getWalletBalance();
        this.geniDexBalance = await this.getGeniDexBalance();
    }

    addWeiFee(fee){
        this.totalFee += fee;
        this.walletBalance -= fee;
    }

    async deposit(amount){
        var _amount = ethers.parseEther(amount);
        let transaction = await this.geniDexContract.connect(this.account).depositEth({value: _amount});
        fn.printGasUsed(transaction, '\ndeposit '+amount+' ETH');
        let weiFee = await this.getWeiFee(transaction);
        // console.log('_amount', _amount);
        // console.log('weiFee', weiFee);
        // console.log(`walletBalance: ${this.walletBalance} - ${_amount} - ${weiFee} = `);
        this.addWeiFee(weiFee);
        this.walletBalance -= _amount;
        this.geniDexBalance += _amount;
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
        let _amount = ethers.parseEther(amount);
        let transaction = await this.geniDexContract.connect(this.account).withdrawEth(_amount);
        // transaction = await geniDexContract.connect(trader1).withdrawEth2(amount);
        // console.log(transaction);
        fn.printGasUsed(transaction, '\nwithdraw '+amount+' ETH');
        let weiFee = await fn.getWeiFee(transaction);
        this.addWeiFee(weiFee);
        this.walletBalance += _amount;
        this.geniDexBalance -= _amount;
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
        const balance = await provider.getBalance(this.account);
        console.log('getWalletBalance', ethers.formatEther(balance).yellow);
        return balance;
    }

    async getGeniDexBalance(){
        const balance = await this.geniDexContract.connect(this.account).getEthBalance();
        console.log('getGeniDexBalance', ethers.formatEther(balance).yellow);
        return balance;
    }

    async getEthBalance(){
        const weiBalance = await provider.getBalance(this.account);
        return ethers.formatEther(weiBalance);
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