
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
        address referrer
    );

    struct PlaceSellOrderVariable{
        address baseAddress;
        address quoteAddress;
        uint256 lastPrice;
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
        if (marketId > marketCounter) {
            revert Helper.InvalidMarketId(marketId, marketCounter);
        }
        Market storage market = markets[marketId];
        //lv: local variable
        PlaceSellOrderVariable memory lv = PlaceSellOrderVariable({
            baseAddress: market.baseAddress,
            quoteAddress: market.quoteAddress,
            lastPrice: 0,
            total: 0,
            userID: userIDs[msg.sender]
        });
        if(lv.userID<=0){
            revert Helper.UserNotFound(msg.sender);
        }

        //set referrer
        if (userReferrer[msg.sender] == address(0)
            && referrer != address(0)
            && referrer != msg.sender)
        {
            userReferrer[msg.sender] = referrer;
            refereesOf[referrer].push(msg.sender);
        }

        lv.total = uint256(price) * quantity / WAD;
        if (lv.total < tokens[lv.quoteAddress].minOrderAmount) {
            revert Helper.TotalTooSmall(lv.total, tokens[lv.quoteAddress].minOrderAmount);
        }

        Order memory sellOrder = Order({
            userID: lv.userID,
            price: price,
            quantity: quantity
        });

        mapping(address => uint256) storage sellerBalances = balances[lv.userID];
        if(sellerBalances[lv.baseAddress] < quantity){
            revert Helper.InsufficientBalance({
                available: sellerBalances[lv.baseAddress],
                required: quantity
            });
        }

        Order[] storage marketSellOrders = sellOrders[marketId];
        // Order[] storage marketBuyOrders = buyOrders[marketId];

        lv.lastPrice = matchSellOrder(marketId, market, sellOrder, buyOrderIDs, lv);
        sellerBalances[lv.baseAddress] -= quantity;

        // lv.remainingValue = price * sellOrder.quantity / WAD;
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
            price, quantity, sellOrder.quantity, lv.lastPrice, referrer);
    }

    function matchSellOrder(
        uint256 marketId,
        Market storage market,
        Order memory sellOrder,
        uint256[] calldata buyOrderIDs,
        PlaceSellOrderVariable memory lv
    ) private returns(uint256 lastPrice)
    {

        lastPrice = 0;
        uint256 length = buyOrderIDs.length;
        if(length==0) return lastPrice;

        Order[] storage marketBuyOrders = buyOrders[marketId];
        // uint256 totalTradeQuantity;
        uint256 totalTradeValue = 0;

        for(uint256 i=0; i<length;){
            if(sellOrder.quantity<=0){
                break;
            }
            uint256 buyOrderID = buyOrderIDs[i];
            Order storage buyOrder = marketBuyOrders[buyOrderID];
            uint80 buyOrderPrice = buyOrder.price;
            uint80 buyOrderQuantity = buyOrder.quantity;
            if (buyOrderPrice >= sellOrder.price && buyOrderQuantity>0) {

                uint80 tradeQuantity = Helper.min(buyOrderQuantity, sellOrder.quantity);
                uint256 tradeValue = uint256(buyOrderPrice) * tradeQuantity / WAD;

                buyOrder.quantity -= tradeQuantity;
                sellOrder.quantity -= tradeQuantity;

                // totalTradeQuantity += tradeQuantity;
                totalTradeValue += tradeValue;

                balances[buyOrder.userID][lv.baseAddress] += tradeQuantity;
                lastPrice = buyOrderPrice;
            }
            unchecked{
                i++;
            }
        }
        if(totalTradeValue>0){
            uint256 totalFee = _fee(totalTradeValue);
            balances[sellOrder.userID][lv.quoteAddress] += (totalTradeValue - totalFee);
            balances[1][lv.quoteAddress] += 2*totalFee;

            //update geniPoints
            if(market.isRewardable){
                _updatePoints(lv.quoteAddress, sellOrder.userID, totalTradeValue);
            }

            // update market.price
            if(block.timestamp - market.lastUpdatePrice > 300){
                market.price = lastPrice;
                market.lastUpdatePrice = block.timestamp;
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

        uint80 userID = userIDs[msg.sender];
        if(userID<=0){
            revert Helper.UserNotFound(msg.sender);
        }
        // Order[] storage marketOrders = sellOrders[marketId];
        address baseAddress = markets[marketId].baseAddress;

        // if(orderIndex >= marketOrders.length){
        //     revert Helper.InvalidValue({providedValue: orderIndex});
        // }

        Order storage order = sellOrders[marketId][orderIndex];
        uint80 orderUserID = order.userID;
        if (userID != orderUserID) {
            revert Helper.Unauthorized(userID, orderUserID);
        }
        uint256 quantity = order.quantity;
        if (quantity == 0) {
            revert Helper.OrderAlreadyCanceled(orderIndex);
        }
        order.quantity = 0;
        balances[orderUserID][baseAddress] += quantity;
        
        emit OnCancelSellOrder(msg.sender, marketId, orderIndex);
    }

    /// @notice Return the total number of sell orders for a market
    function getSellOrdersLength(uint256 marketID) external view returns (uint256) {
        return sellOrders[marketID].length;
    }

    function getSellOrders(
        uint256 marketId,
        uint256 maxPrice,
        uint256 limit
    ) public view returns (OutputOrder[] memory rsSellOrders) {
        Order[] storage orders = sellOrders[marketId];
        uint256 totalOrders = orders.length;

        // Count matching orders first
        uint256 matchCount = 0;
        for (uint256 i = 0; i < totalOrders; i++) {
            if (orders[i].price <= maxPrice) {
                matchCount++;
                if(matchCount>limit) break;
            }
        }

        // Allocate exact size
        rsSellOrders = new OutputOrder[](matchCount);

        uint256 count = 0;
        for (uint256 j = 0; j < totalOrders; j++) {
            if (orders[j].price <= maxPrice) {
                Order storage order = orders[j];
                rsSellOrders[count] = OutputOrder({
                    id: j,
                    userID: order.userID,
                    price: order.price,
                    quantity: order.quantity
                });
                count++;
                if(count>limit) break;
            }
        }
        return rsSellOrders;
    }

}