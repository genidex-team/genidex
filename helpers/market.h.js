
const { ethers, network } = require('hardhat');
const markets = require('./markets.h');
const tokensHelper = require('./tokens.h');
const tokensH = require('./tokens.h');
const geniDexHelper = require('./genidex.h');

const POINT_DECIMALS = 6;
class Market{

    marketId;
    data = {
        "id": 0,
        "baseAddress": "",
        "quoteAddress": "",
        "marketDecimalsPower": "",
        "marketDecimals": 0,
        "priceDecimals": 0,
        "symbol": "",
        "baseDecimals": 0,
        "quoteDecimals": 0,
        "isRewardable": false
    };

    constructor(marketId){
        this.marketId = marketId;
        this.data = markets.getMarket(marketId);
        // console.log(this.data);
    }

    async getPrice(marketId){
        if(!marketId) marketId = this.data.marketId;
        const geniDexContract = await geniDexHelper.getContract();
        const market = await geniDexContract.markets(marketId);
        return market.price;
    }

    parsePrice(price){
        return ethers.parseUnits(
            price.toString(),
            this.data.priceDecimals
        );
    }

    parseQuantity(quantity){
        return ethers.parseUnits(
            quantity.toString(),
            this.data.baseDecimals
        );
    }

    total(price, quantity){
        return price * quantity / ethers.parseUnits('1', this.data.marketDecimals);
    }

    async toPoints(amount){
        let quoteAddress = this.data.quoteAddress;
        let token = tokensHelper.getToken(quoteAddress);
        let points = 0;
        if(this.data.isRewardable!=true) return 0;

        if(token.isUSD == true){
            if( POINT_DECIMALS - token.decimals > 0){
                // points = amount * 10**(POINT_DECIMALS - token.decimals);
                points = amount * ethers.parseUnits('1', POINT_DECIMALS - token.decimals)
            }else{
                // points = amount / 10**(token.decimals - POINT_DECIMALS);
                points = amount * ethers.parseUnits('1', token.decimals - POINT_DECIMALS)
            }
            points = amount;
        }else if(token.usdMarketID > 0){
            let usdMarket = markets.getMarket(token.usdMarketID);
            let usdToken = tokensHelper.getToken(usdMarket.quoteAddress);
            let usdPrice = await this.getPrice(token.usdMarketID);
            let total = amount * usdPrice / ethers.parseUnits('1', usdMarket.marketDecimals);
            if(usdToken.isUSD == true){
                if( POINT_DECIMALS - usdToken.decimals > 0){
                    // points = total * 10n**(POINT_DECIMALS - usdToken.decimals);
                    points = total * ethers.parseUnits('1', POINT_DECIMALS - usdToken.decimals)
                }else{
                    // points = total / 10n**(usdToken.decimals - POINT_DECIMALS);
                    points = total * ethers.parseUnits('1', usdToken.decimals - POINT_DECIMALS)
                }
            }
        }
        console.log(token);
        return points;
    }

}

module.exports = Market;