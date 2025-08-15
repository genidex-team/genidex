
const { ethers } = require('hardhat');
const geniDexHelper = require('./genidex.h');
const config = require('../config/config');
const genidexSDK = config.genidexSDK;

class Points {
    decimals = 6;

    async getPoints(address){
        const geniDexContract = await geniDexHelper.getContract();
        var points = await genidexSDK.getUserPoints(address);
        return points;
    }

    format(value){
        return ethers.formatUnits(value, this.decimals);
    }

}

module.exports = new Points();