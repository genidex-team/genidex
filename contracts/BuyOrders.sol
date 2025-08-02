
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./GeniDexBase.sol";

abstract contract BuyOrders is GeniDexBase {
    // using Math for uint256;
    // using Helper for uint256;

    event OnPlaceBuyOrder(
        uint256 indexed marketId,
        address indexed trader,
        uint256 orderIndex,
        uint256 price,
        uint256 quantity,
        uint256 remainingQuantity,
        uint256 lastPrice,
        address referrer,
        uint80 userID
    );

    struct PlaceBuyOrderVariable {
        address baseAddress;
        address quoteAddress;
        uint256 total;
        uint256 totalTradeValue;
        uint256 totalValue;
        uint80 lastPrice;
        uint256 remainingValue;
        uint80 userID;
    }

    /*struct placeBuyOrderParams {
        uint256 marketId;
        uint256 price;
        uint256 quantity;
        uint256 filledOrderId;
        uint256[] sellOrderIDs;
        address referrer;
    }*/

    function placeBuyOrder(
        uint256 marketId,
        uint80 price,
        uint80 quantity,
        uint256 filledOrderId,
        uint256[] calldata sellOrderIDs,
        address referrer
    ) external nonReentrant whenNotPaused
    {
        Storage.TokenData storage t = Storage.token();
        Storage.UserData storage u = Storage.user();
        Storage.MarketData storage m = Storage.market();
        if (marketId > m.marketCounter) {
            revert Helper.InvalidMarketId(marketId, m.marketCounter);
        }
        Storage.Market storage market = m.markets[marketId];
        //lv: local variable
        PlaceBuyOrderVariable memory lv = PlaceBuyOrderVariable({
            baseAddress: market.baseAddress,
            quoteAddress: market.quoteAddress,
            total: 0,
            totalTradeValue: 0,
            totalValue: 0,
            lastPrice: 0,
            remainingValue: 0,
            userID: u.userIDs[msg.sender]
        });

        if(lv.userID<=0){
            revert Helper.UserNotFound(msg.sender);
        }

        Storage.Order memory buyOrder = Storage.Order({
            userID: lv.userID,
            price: price,
            quantity: quantity
        });

        //set referrer
        if (u.userReferrer[msg.sender] == address(0) && referrer != address(0) && referrer != msg.sender) {
            u.userReferrer[msg.sender] = referrer;
            u.refereesOf[referrer].push(msg.sender);
        }

        lv.total = uint256(price) * quantity / BASE_UNIT;
        if (lv.total < t.tokens[lv.quoteAddress].minOrderAmount) {
            revert Helper.TotalTooSmall(lv.total, t.tokens[lv.quoteAddress].minOrderAmount);
        }

        mapping(address => uint256) storage buyerBalances = u.balances[lv.userID];
        uint256 buyerQuoteBalance = buyerBalances[lv.quoteAddress];
        if(buyerQuoteBalance < lv.total + _fee(lv.total)){
            revert Helper.InsufficientBalance({
                available: buyerQuoteBalance,
                required: lv.total + _fee(lv.total)
            });
        }

        (lv.totalTradeValue, lv.lastPrice) = matchBuyOrder(marketId, market, buyOrder, sellOrderIDs, lv);
        lv.remainingValue = uint256(price) * buyOrder.quantity / BASE_UNIT;
        lv.totalValue = lv.totalTradeValue + lv.remainingValue;

        // debit the buyOrder's balance
        buyerBalances[lv.quoteAddress] = buyerQuoteBalance - lv.totalValue - _fee(lv.totalValue);

        // credit the feeReceiver's balance
        // seller fee + buyer fee = 2*_fee(lv.totalTradeValue)
        u.balances[FEE_USER_ID][lv.quoteAddress] += 2 * _fee(lv.totalTradeValue);

        Storage.Order[] storage marketBuyOrders = m.buyOrders[marketId];

        uint256 orderIndex = 0;
        if(buyOrder.quantity>0){
            if(filledOrderId < marketBuyOrders.length && marketBuyOrders[filledOrderId].quantity<=0){
                marketBuyOrders[filledOrderId] = buyOrder;
                orderIndex = filledOrderId;
            }else{
                marketBuyOrders.push(buyOrder);
                orderIndex = marketBuyOrders.length-1;
            }
        }

        emit OnPlaceBuyOrder(marketId, msg.sender, orderIndex,
            price, quantity, buyOrder.quantity, lv.lastPrice, referrer, lv.userID);

    }

    function matchBuyOrder(
        uint256 marketId,
        Storage.Market storage market,
        Storage.Order memory buyOrder,
        uint256[] calldata sellOrderIDs,
        PlaceBuyOrderVariable memory lv
    ) private returns(uint256 totalTradeValue, uint80 lastPrice)
    {
        // CoreConfig storage c = Storage.core();
        // Storage.TokenData storage t = Storage.token();
        Storage.UserData storage u = Storage.user();
        Storage.MarketData storage m = Storage.market();
        //matchBuyOrder
        totalTradeValue = 0;
        lastPrice = 0;
        uint256 length = sellOrderIDs.length;
        if(length==0) return (totalTradeValue, lastPrice);

        Storage.Order[] storage marketSellOrders = m.sellOrders[marketId];
        uint256 totalTradeQuantity = 0;
        for(uint256 i=0; i<length;){
            if(buyOrder.quantity<=0){
                break;
            }
            // uint256 sellOrderID = sellOrderIDs[i];
            Storage.Order storage sellOrder = marketSellOrders[sellOrderIDs[i]];
            uint80 sellOrderPrice = sellOrder.price;
            uint80 sellOrderQuantity = sellOrder.quantity;
            if (sellOrderPrice <= buyOrder.price && sellOrderQuantity>0) {

                uint80 tradeQuantity = Helper._min(buyOrder.quantity, sellOrderQuantity);
                // uint80 tradeQuantity = sellOrderQuantity <=  buyOrder.quantity ? sellOrderQuantity : buyOrder.quantity;
                uint256 tradeValue = uint256(sellOrderPrice) * tradeQuantity / BASE_UNIT;

                // storage
                sellOrder.quantity = sellOrderQuantity - tradeQuantity;

                // memory
                buyOrder.quantity -= tradeQuantity;
                totalTradeQuantity += tradeQuantity;
                totalTradeValue += tradeValue;

                // credit (quote token) the seller's balance
                u.balances[sellOrder.userID][lv.quoteAddress] += tradeValue - _fee(tradeValue);
                lastPrice = sellOrderPrice;
            }
            unchecked{
                i++;
            }
        }
        if(totalTradeValue>0){
            // credit (base token) the buyer's balance
            u.balances[buyOrder.userID][lv.baseAddress] += totalTradeQuantity;

            //update geniPoints
            if(market.isRewardable){
                _updatePoints(lv.quoteAddress, buyOrder.userID, totalTradeValue);
            }

            // update market.price
            if(block.timestamp - market.lastUpdatePrice > 300){
                market.price = lastPrice;
                market.lastUpdatePrice = uint80(block.timestamp);
            }
        }
        return (totalTradeValue, lastPrice);
    }

    event OnCancelBuyOrder(address indexed trader, uint256 indexed marketId, uint256 orderIndex);

    function cancelBuyOrder(
        uint256 marketId,
        uint256 orderIndex
    ) external nonReentrant whenNotPaused
    {
        Storage.UserData storage u = Storage.user();
        Storage.MarketData storage m = Storage.market();
        uint80 userID = u.userIDs[msg.sender];
        if(userID<=0){
            revert Helper.UserNotFound(msg.sender);
        }
        //InvalidValue
        // Order[] storage marketOrders = buyOrders[marketId];
        address quoteAddress = m.markets[marketId].quoteAddress;

        // if(orderIndex >= marketOrders.length){
        //     revert Helper.InvalidValue({providedValue: orderIndex});
        // }

        Storage.Order storage order = m.buyOrders[marketId][orderIndex];
        uint80 orderUserID = order.userID;
        if (userID != orderUserID) {
            revert Helper.Unauthorized(userID, orderUserID);
        }
        uint256 quantity = order.quantity;
        if (quantity == 0) {
            revert Helper.OrderAlreadyCanceled(orderIndex);
        }
        uint256 total = quantity * order.price / BASE_UNIT;
        order.quantity = 0;
        u.balances[orderUserID][quoteAddress] += total + _fee(total);

        emit OnCancelBuyOrder(msg.sender, marketId, orderIndex);
    }

}