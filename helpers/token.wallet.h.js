
const fs = require('fs');
const expect = require('chai').expect;
const { ethers, upgrades, waffle } = require('hardhat');
const geniDexHelper = require('./genidex.h');
const fn = require('./functions');
const erc20Abi = require('../data/erc20.abi.json');
const data = require('./data');
const { genidexSDK } = require('../config/config');

const provider = ethers.provider;

var geniDexAddress, geniDexContract;
var deployer, trader1, trader2;

class TokenWalletHelper{

    async init(){
        [deployer, trader1, trader2] = await ethers.getSigners();
        geniDexAddress = data.get('geniDexAddress');
        geniDexContract = await geniDexHelper.getContract();
    }

    async withdraw(tokenAddress, account, amount){
        var decimals, symbol, balance, transaction;
        console.log(tokenAddress);
        // try{
            if(tokenAddress == ethers.ZeroAddress){
                decimals = 18;
                symbol = 'ETH';
                balance = await ethers.provider.getBalance(account.address);
                var _amount = ethers.parseUnits(amount, decimals);
                transaction = await geniDexContract.connect(account).withdrawEth(_amount);
            }else {
                let token = new ethers.Contract(tokenAddress, erc20Abi, account);
                decimals = await token.decimals();
                symbol = await token.symbol();
                var _amount = ethers.parseUnits(amount, decimals);
                try{
                    transaction = await geniDexContract.connect(account).withdrawToken(tokenAddress, _amount);
                }catch(error){
                    console.dir(error, { depth: null });
                    console.log(typeof error, error)
                }
                
            }
        // }catch(error){
        //     // console.error('Transaction failed===:', error);
        //     JSON.stringify(error, null, 2)
        // }
        
        fn.printGasUsed(transaction, 'withdraw '+amount + ' ' + symbol );
        return transaction;
    }

    async deposit(tokenAddress, account, strAmount){
        var decimals, symbol, balance, transaction;
        // console.log(tokenAddress);
        if(tokenAddress == ethers.ZeroAddress){
            decimals = 18;
            symbol = 'ETH';
            balance = await ethers.provider.getBalance(account.address);
            var normAmount = ethers.parseEther(strAmount);
            transaction = await geniDexContract.connect(account).depositEth({value: normAmount});
        }else{
            let token = new ethers.Contract(tokenAddress, erc20Abi, account);
            decimals = await token.decimals();
            symbol = await token.symbol();

            transaction = await genidexSDK.balances.depositToken({
                signer: account,
                tokenAddress: tokenAddress,
                normAmount: ethers.parseEther(strAmount),
                normApproveAmount: ethers.parseEther(strAmount)
            })
        }
        fn.printGasUsed(transaction, `Deposit ${strAmount} ${symbol}` );
        return transaction;
    }

    async getWalletBalance(message, tokenAddress, account){
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
        
        console.log('getWalletBalance', message, symbol, parseFloat(ethers.formatUnits(balance, decimals)));
        return balance;
    }

    async getGeniDexBalance(message, tokenAddress, account, format){
        var symbol;
        // console.log(tokenAddress);
        if(tokenAddress == ethers.ZeroAddress){
            // decimals = 18;
            symbol = 'ETH';
        }else{
            let token = new ethers.Contract(tokenAddress, erc20Abi, account);
            // decimals = await token.decimals();
            symbol = await token.symbol();
        }
        const balance = await geniDexContract.connect(account).getTokenBalance(tokenAddress);
        
        console.log('getGeniDexBalance', message, symbol, parseFloat(ethers.formatEther(balance)));
        if(format==true){
            return parseFloat(ethers.formatEther(balance));
        }else{
            return balance;
        }
    }

}

module.exports = new TokenWalletHelper();