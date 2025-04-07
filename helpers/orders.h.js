
const { ethers, upgrades, waffle, network } = require('hardhat');
const data = require('./data');
const geniDexHelper = require('./genidex.h');
const fn = require('./functions');
const markets = require('./markets.h');
const tokens = require('../../genidex_nodejs/data/' + network.name + '_tokens.json');

var geniDexContract, geniDexAddress;
var deployer, trader1, trader2;

class BuyOrdersHelper {

    async init() {
        [deployer, trader1, trader2] = await ethers.getSigners();
        geniDexAddress = data.get('geniDexAddress');
        geniDexContract = await geniDexHelper.getContract();
    }

    async placeBuyOrder(account, marketId, price, quantity, referrer) {
        if(!referrer){
            referrer = ethers.ZeroAddress;
        }
        let market = markets.getMarket(marketId);
        let { baseAddress, quoteAddress } = market;
        let baseDecimals = tokens[baseAddress].decimals;
        // console.log('market.priceDecimals', market.priceDecimals)

        // price_ = fn.toFixedDecimal(price_, market.priceDecimals);
        // quantity_ = fn.toFixedDecimal(quantity_, baseDecimals);

        // let price = ethers.parseUnits(price_.toString(), market.priceDecimals);
        // // console.log('price', price);
        // let quantity = ethers.parseUnits(quantity_.toString(), baseDecimals);

        let sellOrderIDs = await this.getSellOrderIDsMatchingBuyOrder(marketId, { price: price, quantity: quantity });
        // console.log('sellOrderIDs', sellOrderIDs);
        let filledBuyOrderID = await this.randomFilledBuyOrderID(marketId);
        // console.log('sellOrderIDs', sellOrderIDs)
        // console.log('filledBuyOrderID', filledBuyOrderID)
        // console.log('placeBuyOrder', {price: price_, quantity: quantity_});
        try{
            let transaction = await geniDexContract.connect(account)
            .placeBuyOrder(marketId, price, quantity, filledBuyOrderID, sellOrderIDs, referrer);
            await fn.printGasUsed(transaction, 'placeBuyOrder');
            const receipt = await transaction.wait();
            // console.log(receipt.logs);
            for(var i in receipt.logs){
                var log = receipt.logs[i];
                if (log.fragment.name === "OnPlaceBuyOrder") {
                    // console.log("OnPlaceBuyOrder:", log.args.orderIndex);
                    return log.args.orderIndex;
                }
            }
        }catch(error){
            geniDexHelper.throwError(error);
        }
    }
    
    async placeBuyOrder_gasPrice(account, marketId, price_, quantity_, gas_rice = '10') {
        console.log('account',account)
        let market = markets.getMarket(marketId);
        let { baseAddress, quoteAddress } = market;
        let baseDecimals = tokens[baseAddress].decimals;
        // console.log('market.priceDecimals', market.priceDecimals)

        // price_ = fn.toFixedDecimal(price_, market.priceDecimals);
        // quantity_ = fn.toFixedDecimal(quantity_, baseDecimals);

        let price = ethers.parseUnits(price_.toString(), market.priceDecimals);
        // console.log('price', price);
        let quantity = ethers.parseUnits(quantity_.toString(), baseDecimals);

        let sellOrderIDs = await this.getSellOrderIDsMatchingBuyOrder(marketId, { price: price, quantity: quantity });
        // console.log('sellOrderIDs', sellOrderIDs);
        let filledBuyOrderID = await this.randomFilledBuyOrderID(marketId);
        // console.log('filledBuyOrderID', filledBuyOrderID);
        console.log('sellOrderIDs', sellOrderIDs)
        console.log('filledBuyOrderID', filledBuyOrderID)
        // console.log('placeBuyOrder', {price: price_, quantity: quantity_});
        let transaction = await geniDexContract.connect(account).placeBuyOrder(marketId, price, quantity, sellOrderIDs, filledBuyOrderID, { gasPrice: ethers.parseUnits(gas_rice, 'gwei') });
        await fn.printGasUsed(transaction, 'placeBuyOrder');
    }

    async placeSellOrder(account, marketId, price, quantity, referrer) {
        if(!referrer){
            referrer = ethers.ZeroAddress;
        }
        let market = markets.getMarket(marketId);
        let { baseAddress, quoteAddress } = market;
        let baseDecimals = tokens[baseAddress].decimals;

        // price_ = fn.toFixedDecimal(price_, market.priceDecimals);
        // quantity_ = fn.toFixedDecimal(quantity_, baseDecimals);

        // let price = ethers.parseUnits(price_.toString(), market.priceDecimals);
        // // console.log('price', price);
        // let quantity = ethers.parseUnits(quantity_.toString(), baseDecimals);

        let buyOrderIDs = await this.getBuyOrderIDsMatchingSellOrder(marketId, { price: price, quantity: quantity });
        console.log('buyOrderIDs', buyOrderIDs);
        let filledSellOrderID = await this.randomFilledSellOrderID(marketId);
        // console.log('filledSellOrderID', filledSellOrderID)
        // console.log(marketId, price, quantity, filledSellOrderID, buyOrderIDs);
        try{
            let transaction = await geniDexContract.connect(account)
            .placeSellOrder(marketId, price, quantity, filledSellOrderID, buyOrderIDs, referrer);
            await fn.printGasUsed(transaction, 'placeSellOrder');
            const receipt = await transaction.wait();
            // console.log(receipt.logs);
            for(var i in receipt.logs){
                var log = receipt.logs[i];
                if (log.fragment.name === "OnPlaceSellOrder") {
                    // console.log("OnPlaceBuyOrder:", log.args.orderIndex);
                    return log.args.orderIndex;
                }
            }
        }catch(error){
            geniDexHelper.throwError(error);
        }
        
    }

    async cancelBuyOrder(account, marketId, orderIndex) {
        // let market = markets.getMarket(marketId);
        // let { baseAddress, quoteAddress } = market;
        // try{
            let transaction = await geniDexContract.connect(account).cancelBuyOrder(marketId, orderIndex);
            await fn.printGasUsed(transaction, 'cancelBuyOrder');
        // }catch(error){
        //     console.log(`error`, error)
        //     geniDexHelper.throwError(error);
        // }
        
    }

    async cancelSellOrder(account, marketId, orderIndex) {
        // let market = markets.getMarket(marketId);
        // let { baseAddress, quoteAddress } = market;
        // console.log('\n\n===cancelSellOrder');
        try{
            let transaction = await geniDexContract.connect(account).cancelSellOrder(marketId, orderIndex);
            await fn.printGasUsed(transaction, 'cancelSellOrder');
        }catch(error){
            // console.log(error);
            geniDexHelper.throwError(error);
        }
    }

    async getBuyOrders(marketId) {
        let market = markets.getMarket(marketId);
        try{
            let buyOrderData = await geniDexContract.getBuyOrders(marketId);
            var buyOrders = [];
            for (var id in buyOrderData) {
                let buyOrder = buyOrderData[id];
                buyOrders.push({
                    id: parseInt(id),
                    price: buyOrder.price,
                    quantity: buyOrder.quantity,
                    // total: ethers.formatUnits(buyOrder.price * buyOrder.quantity, market.totalDecimals)
                });
            }
            return buyOrders;
        }catch(error){
            geniDexHelper.throwError(error);
        }
        
    }

    async getSellOrders(marketId) {
        let sellOrderData = await geniDexContract.getSellOrders(marketId);
        var sellOrders = [];
        for (var id in sellOrderData) {
            let item = sellOrderData[id];
            sellOrders.push({
                id: parseInt(id),
                trader: item.trader,
                price: item.price,
                quantity: item.quantity
            });
        }
        return sellOrders;
    }

    async getDescFormatBuyOrders(marketId) {
        let market = markets.getMarket(marketId);
        // console.log(market);
        let { baseAddress, priceDecimals } = market;
        let baseDecimals = tokens[baseAddress].decimals;
        var buyOrders = await this.getDescBuyOrders(marketId);
        for (var i in buyOrders) {
            var { id, price, quantity } = buyOrders[i];
            buyOrders[i] = {
                id: id,
                price: parseFloat(ethers.formatUnits(price, priceDecimals)),
                quantity: parseFloat(ethers.formatUnits(quantity, baseDecimals))
            }
        }
        return buyOrders;
    }

    async getAscFormatSellOrders(marketId) {
        let market = markets.getMarket(marketId);
        let { baseAddress, priceDecimals } = market;
        let baseDecimals = tokens[baseAddress].decimals;
        var sellOrders = await this.getAscSellOrders(marketId);
        for (var i in sellOrders) {
            var { id, trader, price, quantity } = sellOrders[i];
            sellOrders[i] = {
                id: id,
                // trader: trader,
                price: parseFloat(ethers.formatUnits(price, priceDecimals)),
                quantity: parseFloat(ethers.formatUnits(quantity, baseDecimals))
            }
        }
        return sellOrders;
    }

    async getFilledBuyOrderIDs(marketId) {
        let buyOrders = await this.getBuyOrders(marketId);
        var orderIDs = [];
        for (var i in buyOrders) {
            let buyOrder = buyOrders[i];
            if (buyOrder.quantity <= 0) {
                orderIDs.push(buyOrder.id);
            }
        }
        return orderIDs;
    }

    async randomFilledBuyOrderID(marketId) {
        let orderIDs = await this.getFilledBuyOrderIDs(marketId);
        if (orderIDs.length == 0) {
            return 0;
        }
        const random = Math.floor(Math.random() * orderIDs.length);
        return orderIDs[random];
    }

    async getFilledSellOrderIDs(marketId) {
        let sellOrders = await this.getSellOrders(marketId);
        var orderIDs = [];
        for (var i in sellOrders) {
            let sellOrder = sellOrders[i];
            if (sellOrder.quantity <= 0) {
                orderIDs.push(sellOrder.id);
            }
        }
        return orderIDs;
    }

    async randomFilledSellOrderID(marketId) {
        let orderIDs = await this.getFilledSellOrderIDs(marketId);
        if (orderIDs.length == 0) {
            return 0;
        }
        const random = Math.floor(Math.random() * orderIDs.length);
        return orderIDs[random];
    }


    asc(a, b) {
        if (a.price < b.price) { return -1; }
        if (a.price > b.price) { return 1; }
        return 0;
    }

    desc(a, b) {
        if (a.price < b.price) { return 1; }
        if (a.price > b.price) { return -1; }
        return 0;
    }

    async getDescBuyOrders(marketId) {
        let buyOrders = await this.getBuyOrders(marketId);
        return buyOrders.sort(this.desc);
    }

    async getAscSellOrders(marketId) {
        let sellOrders = await this.getSellOrders(marketId);
        return sellOrders.sort(this.asc);
    }

    //buyOrder = {price:..., quantity:...}
    async getSellOrderIDsMatchingBuyOrder(marketId, buyOrder) {
        var sellOrderIDs = [];
        let sellOrders = await this.getAscSellOrders(marketId);
        // console.log('sellOrders', sellOrders);
        var quantitySum = 0n;
        for (var i in sellOrders) {
            let sellOrder = sellOrders[i];
            if (sellOrder.price > buyOrder.price) {
                break;
            }
            // console.log(i, quantitySum, buyOrder.quantity)
            if(quantitySum >= buyOrder.quantity){
                break;
            }
            if (sellOrder.quantity <= 0n) {
                continue;
            }
            sellOrderIDs.push(sellOrder.id);
            quantitySum += sellOrder.quantity;
        }
        return sellOrderIDs;
    }

    async getBuyOrderIDsMatchingSellOrder(marketId, sellOrder) {
        var buyOrderIDs = [];
        let buyOrders = await this.getDescBuyOrders(marketId);
        var quantitySum = 0n;
        for (var i in buyOrders) {
            let buyOrder = buyOrders[i];
            if (buyOrder.price < sellOrder.price) {
                break;
            }
            if(quantitySum > sellOrder.quantity){
                break;
            }
            if (buyOrder.quantity <= 0n) {
                continue;
            }
            buyOrderIDs.push(buyOrder.id);
            quantitySum += buyOrder.quantity;
        }
        return buyOrderIDs;
    }

    async cancelAllSellOrder(marketId){
        // console.log('\n===cancelAllSellOrder===')
        let sellOrders = await this.getSellOrders(marketId);
        console.log('sellOrders', sellOrders);
        for(var i in sellOrders){
            var sellOrder = sellOrders[i];
            if(sellOrder.quantity>0){
                await this.cancelSellOrder(trader2, marketId, sellOrder.id);
            }
        }
        sellOrders = await this.getSellOrders(marketId);
        // console.log('sellOrders', sellOrders);
        // console.log('======')
    }
    
    async cancelAllBuyOrder(marketId){
        // console.log('\n===cancelAllBuyOrder===')
        let buyOrders = await this.getBuyOrders(marketId);
        // console.log('buyOrders', buyOrders);
        for(var i in buyOrders){
            var buyOrder = buyOrders[i];
            if(buyOrder.quantity>0){
                await this.cancelBuyOrder(trader1, marketId, buyOrder.id);
            }
        }
        buyOrders = await this.getBuyOrders(marketId);
        // console.log('buyOrders', buyOrders);
        // console.log('======')
    }

}

module.exports = new BuyOrdersHelper();