
const hre = require("hardhat");
const { ethers } = require("ethers");
var crypto = require('crypto');

const {gasPrice, ethPrice } = hre.config.data;

class Function{

    toFixedDecimal(value, decimals){
        if(decimals > 14){
            decimals = 14;
        }
        return value.toFixed(decimals);
    }

    toFixedFloor(value, decimals){
        return (Math.floor(value * 10**decimals) / 10**decimals).toString();
    }

    parseUnits(amount, decimals){
        return ethers.parseUnits(this.toFixedFloor(amount, decimals), decimals);
    }

    randomAddress(){
        var id = crypto.randomBytes(32).toString('hex');
        var privateKey = "0x"+id;
        var wallet = new ethers.Wallet(privateKey);
        return wallet.address;
    }

    randomDecimal(min, max, decimals) {
        return this.randomFloat(min, max).toFixed(decimals);
    }
    
    randomFloat(min, max) {
        return Math.random() * (max - min) + min;
    }

    randomInt(min, max) {
        min = Math.ceil(min);
        max = Math.floor(max);
        return Math.floor(Math.random() * (max - min + 1)) + min;
    }

    async printGasUsed(transaction, label){
        var gasUsed = await this.getGasUsed(transaction);
        var usdValue = this.gasToUSD(gasUsed);
        gasUsed = new Intl.NumberFormat("en").format( gasUsed );
        if(label){
            console.log(label, '- gasUsed:', gasUsed.yellow, '-', usdValue.yellow, 'USD');
        }else{
            console.log('gasUsed:', gasUsed.yellow, '-', usdValue.yellow, 'USD');
        }
    }

    gasToEth(gas){
        var weiValue = BigInt(gas) * gasPrice;
        var ethValue = ethers.formatUnits(weiValue, 18);
        // console.log('ethValue', ethValue)
        return ethValue;
    }

    gasToUSD(gas){
        var ethValue = this.gasToEth(gas);
        var usdValue = ethValue * ethPrice;
        usdValue = usdValue.toFixed(4);
        return usdValue;
    }

    async getGasUsed(transaction){
        const transactionReceipt = await transaction.wait();
        return transactionReceipt.gasUsed;
    }

    async getWeiFee(transaction){
        const transactionReceipt = await transaction.wait();
        const {gasUsed, gasPrice} = transactionReceipt;
        // console.log('transaction', transaction);
        // console.log('transactionReceipt', transactionReceipt);
        // const block = await provider.getBlock(transaction.blockNumber);
        console.log('block.baseFeePerGas', block.baseFeePerGas)
        return gasUsed*gasPrice;

        // Calculate total fee
        // const gasUsed = transactionReceipt.gasUsed;
        // const gasPrice = transactionReceipt.gasPrice; // For legacy transactions
        // const baseFee = transaction.maxFeePerGas || 0; // For EIP-1559 transactions
        // const priorityFee = transaction.maxPriorityFeePerGas || 0; // For EIP-1559 transactions

        // // Total fee calculation for EIP-1559
        // const totalFee = gasUsed * (baseFee + priorityFee);
        // return totalFee * gasPrice;
    }

}

module.exports = new Function();