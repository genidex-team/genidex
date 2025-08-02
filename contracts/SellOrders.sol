
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./GeniDexBase.sol";

abstract contract SellOrders is GeniDexBase {

    event OnPlaceSellOrder(
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

    struct PlaceSellOrderVariable{
        address baseAddress;
        address quoteAddress;
        uint80 lastPrice;
        uint256 total;
        uint80 userID;
    }

    /*struct placeSellOrderParams {
        uint256 marketId;
        uint256 price;
        uint256 quantity;
        uint256 filledOrderId;
        uint256[] buyOrderIDs;
        address referrer;
    }*/

    function placeSellOrder(
        uint256 marketId,
        uint80 price,
        uint80 quantity,
        uint256 filledOrderId,
        uint256[] calldata buyOrderIDs,
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
        PlaceSellOrderVariable memory lv = PlaceSellOrderVariable({
            baseAddress: market.baseAddress,
            quoteAddress: market.quoteAddress,
            lastPrice: 0,
            total: 0,
            userID: u.userIDs[msg.sender]
        });
        if(lv.userID<=0){
            revert Helper.UserNotFound(msg.sender);
        }

        //set referrer
        if (u.userReferrer[msg.sender] == address(0)
            && referrer != address(0)
            && referrer != msg.sender)
        {
            u.userReferrer[msg.sender] = referrer;
            u.refereesOf[referrer].push(msg.sender);
        }

        lv.total = uint256(price) * quantity / BASE_UNIT;
        if (lv.total < t.tokens[lv.quoteAddress].minOrderAmount) {
            revert Helper.TotalTooSmall(lv.total, t.tokens[lv.quoteAddress].minOrderAmount);
        }

        Storage.Order memory sellOrder = Storage.Order({
            userID: lv.userID,
            price: price,
            quantity: quantity
        });

        mapping(address => uint256) storage sellerBalances = u.balances[lv.userID];
        if(sellerBalances[lv.baseAddress] < quantity){
            revert Helper.InsufficientBalance({
                available: sellerBalances[lv.baseAddress],
                required: quantity
            });
        }

        Storage.Order[] storage marketSellOrders = m.sellOrders[marketId];
        // Order[] storage marketBuyOrders = buyOrders[marketId];

        lv.lastPrice = matchSellOrder(marketId, market, sellOrder, buyOrderIDs, lv);
        sellerBalances[lv.baseAddress] -= quantity;

        // lv.remainingValue = price * sellOrder.quantity / BASE_UNIT;
        uint256 orderIndex = 0;
        if(sellOrder.quantity>0){
            if(filledOrderId < marketSellOrders.length && marketSellOrders[filledOrderId].quantity<=0){
                marketSellOrders[filledOrderId] = sellOrder;
                orderIndex = filledOrderId;
            }else{
                marketSellOrders.push(sellOrder);
                orderIndex = marketSellOrders.length-1;
            }
        }
        emit OnPlaceSellOrder(marketId, msg.sender, orderIndex,
            price, quantity, sellOrder.quantity, lv.lastPrice, referrer, lv.userID);
    }

    function matchSellOrder(
        uint256 marketId,
        Storage.Market storage market,
        Storage.Order memory sellOrder,
        uint256[] calldata buyOrderIDs,
        PlaceSellOrderVariable memory lv
    ) private returns(uint80 lastPrice)
    {
        Storage.UserData storage u = Storage.user();
        Storage.MarketData storage m = Storage.market();
        lastPrice = 0;
        uint256 length = buyOrderIDs.length;
        if(length==0) return lastPrice;

        Storage.Order[] storage marketBuyOrders = m.buyOrders[marketId];
        // uint256 totalTradeQuantity;
        uint256 totalTradeValue = 0;

        for(uint256 i=0; i<length;){
            if(sellOrder.quantity<=0){
                break;
            }
            uint256 buyOrderID = buyOrderIDs[i];
            Storage.Order storage buyOrder = marketBuyOrders[buyOrderID];
            uint80 buyOrderPrice = buyOrder.price;
            uint80 buyOrderQuantity = buyOrder.quantity;
            if (buyOrderPrice >= sellOrder.price && buyOrderQuantity>0) {

                uint80 tradeQuantity = Helper._min(buyOrderQuantity, sellOrder.quantity);
                // uint80 tradeQuantity = buyOrderQuantity <= sellOrder.quantity ? buyOrderQuantity : sellOrder.quantity;
                uint256 tradeValue = uint256(buyOrderPrice) * tradeQuantity / BASE_UNIT;

                buyOrder.quantity = buyOrderQuantity - tradeQuantity;
                sellOrder.quantity -= tradeQuantity;

                // totalTradeQuantity += tradeQuantity;
                totalTradeValue += tradeValue;

                u.balances[buyOrder.userID][lv.baseAddress] += tradeQuantity;
                lastPrice = buyOrderPrice;
            }
            unchecked{
                i++;
            }
        }
        if(totalTradeValue>0){
            uint256 totalFee = _fee(totalTradeValue);
            u.balances[sellOrder.userID][lv.quoteAddress] += (totalTradeValue - totalFee);
            u.balances[FEE_USER_ID][lv.quoteAddress] += 2*totalFee;

            //update geniPoints
            if(market.isRewardable){
                _updatePoints(lv.quoteAddress, sellOrder.userID, totalTradeValue);
            }

            // update market.price
            if(block.timestamp - market.lastUpdatePrice > 300){
                market.price = lastPrice;
                market.lastUpdatePrice = uint80(block.timestamp);
            }
        }
        return lastPrice;
    }

    event OnCancelSellOrder(address indexed trader, uint256 indexed marketId, uint256 orderIndex);

    function cancelSellOrder(
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
        // Order[] storage marketOrders = sellOrders[marketId];
        address baseAddress = m.markets[marketId].baseAddress;

        // if(orderIndex >= marketOrders.length){
        //     revert Helper.InvalidValue({providedValue: orderIndex});
        // }

        Storage.Order storage order = m.sellOrders[marketId][orderIndex];
        uint80 orderUserID = order.userID;
        if (userID != orderUserID) {
            revert Helper.Unauthorized(userID, orderUserID);
        }
        uint80 quantity = order.quantity;
        if (quantity == 0) {
            revert Helper.OrderAlreadyCanceled(orderIndex);
        }
        order.quantity = 0;
        u.balances[orderUserID][baseAddress] += quantity;
        
        emit OnCancelSellOrder(msg.sender, marketId, orderIndex);
    }

}