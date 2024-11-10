
const fs = require('fs');
const expect = require('chai').expect;
const { ethers, upgrades, waffle } = require('hardhat');
const geniDexHelper = require('./genidex.h');
const fn = require('./functions');
const erc20Abi = require('../data/erc20.abi.json');
const data = require('./data');

const provider = ethers.provider;

var geniDexAddress, geniDexContract;

class TokenWalletHelper{

    async init(){
        [deployer, trader1, trader2] = await ethers.getSigners();
        geniDexAddress = data.get('geniDexAddress');
        geniDexContract = await geniDexHelper.getContract();
    }

    async deposit(tokenAddress, account, amount){
        var decimals, symbol, balance, transaction;
        // console.log(tokenAddress);
        if(tokenAddress == ethers.ZeroAddress){
            decimals = 18;
            symbol = 'ETH';
            balance = await ethers.provider.getBalance(account.address);
            var _amount = ethers.parseUnits(amount, decimals);
            transaction = await geniDexContract.connect(account).depositEth({value: _amount});
        }else{
            let token = new ethers.Contract(tokenAddress, erc20Abi, account);
            decimals = await token.decimals();
            symbol = await token.symbol();
            var _amount = ethers.parseUnits(amount, decimals);
            await token.approve(geniDexAddress, _amount);
            transaction = await geniDexContract.connect(account).depositToken(tokenAddress, _amount);
        }
        fn.printGasUsed(transaction, 'deposit '+amount + ' ' + symbol );
    }

    async getOnChainBalance(message, tokenAddress, account){
        var decimals, symbol, balance;
        // console.log(tokenAddress);
        if(tokenAddress == ethers.ZeroAddress){
            decimals = 18;
            symbol = 'ETH';
            balance = await ethers.provider.getBalance(account.address);
        }else{
            let token = new ethers.Contract(tokenAddress, erc20Abi, account);
            // console.log('tokenAddress', tokenAddress)
            balance = await token.balanceOf(account);
            decimals = await token.decimals();
            symbol = await token.symbol();
        }
        
        console.log('getOnChainBalance', message, symbol, parseFloat(ethers.formatUnits(balance, decimals)));
        return balance;
    }

    async getGeniDexBalance(message, tokenAddress, account, format){
        var decimals, symbol;
        // console.log(tokenAddress);
        if(tokenAddress == ethers.ZeroAddress){
            decimals = 18;
            symbol = 'ETH';
        }else{
            let token = new ethers.Contract(tokenAddress, erc20Abi, account);
            decimals = await token.decimals();
            symbol = await token.symbol();
        }
        const balance = await geniDexContract.connect(account).getTokenBalance(tokenAddress);
        
        console.log('getGeniDexBalance', message, symbol, parseFloat(ethers.formatUnits(balance, decimals)));
        if(format==true){
            return parseFloat(ethers.formatUnits(balance, decimals));
        }else{
            return balance;
        }
    }

}

module.exports = new TokenWalletHelper();