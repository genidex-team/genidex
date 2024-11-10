
const markets = require('../../genidex_nodejs/data/'+network.name+'_markets.json');

class Markets{

    getMarket(marketId){
        return markets[marketId];
    }

}

module.exports = new Markets();