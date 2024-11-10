
const { ethers } = require('hardhat');
const geniDexHelper = require('./genidex.h');

class Points {
    decimals = 6;

    async getPoints(address){
        const geniDexContract = await geniDexHelper.getContract();
        var points = await geniDexContract.geniPoints(address);
        return points;
    }

    format(value){
        return ethers.formatUnits(value, this.decimals);
    }

}

module.exports = new Points();