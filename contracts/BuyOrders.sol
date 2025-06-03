
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
        address referrer
    );

    struct PlaceBuyOrderVariable {
        address baseAddress;
        address quoteAddress;
        uint256 total;
        uint256 totalTradeValue;
        uint256 totalValue;
        uint256 lastPrice;
        uint256 remainingValue;
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
        uint256 price,
        uint256 quantity,
        uint256 filledOrderId,
        uint256[] calldata sellOrderIDs,
        address referrer
    ) external nonReentrant whenNotPaused
    {
        if (marketId > marketCounter) {
            revert Helper.InvalidMarketId('BO55', marketId, marketCounter);
        }
        Market storage market = markets[marketId];
        //lv: local variable
        PlaceBuyOrderVariable memory lv = PlaceBuyOrderVariable({
            baseAddress: market.baseAddress,
            quoteAddress: market.quoteAddress,
            total: 0,
            totalTradeValue: 0,
            totalValue: 0,
            lastPrice: 0,
            remainingValue: 0
        });

        Order memory buyOrder = Order({
            trader: msg.sender,
            price: price,
            quantity: quantity
        });

        //set referrer
        if (userReferrer[msg.sender] == address(0)
            && referrer != address(0)
            && referrer != msg.sender)
        {
            userReferrer[msg.sender] = referrer;
            refereesOf[referrer].push(msg.sender);
        }

        lv.total = price * quantity / WAD;
        if (lv.total < tokens[lv.quoteAddress].minOrderAmount) {
            revert Helper.TotalTooSmall('BO68', lv.total, tokens[lv.quoteAddress].minOrderAmount);
        }

        mapping(address => uint256) storage buyerBalances = balances[buyOrder.trader];
        if(buyerBalances[lv.quoteAddress] < lv.total + _fee(lv.total)){
            revert Helper.InsufficientBalance({
                code: 'BO73',
                available: buyerBalances[lv.quoteAddress],
                required: lv.total + _fee(lv.total)
            });
        }

        (lv.totalTradeValue, lv.lastPrice) = matchBuyOrder(marketId, market, buyOrder, sellOrderIDs, lv);
        lv.remainingValue = price * buyOrder.quantity / WAD;
        lv.totalValue = lv.totalTradeValue + lv.remainingValue;

        //debit the buyOrder's balance
        buyerBalances[lv.quoteAddress] -= lv.totalValue + _fee(lv.totalValue);

        //credit the feeReceiver's balance
        // seller fee + buyer fee = 2*_fee(lv.totalTradeValue)
        balances[feeReceiver][lv.quoteAddress] += 2 * _fee(lv.totalTradeValue);

        //  Order[] storage marketSellOrders = sellOrders[marketId];
        Order[] storage marketBuyOrders = buyOrders[marketId];

        uint256 orderIndex = 0;
        if(lv.remainingValue>0){
            if(filledOrderId < marketBuyOrders.length && marketBuyOrders[filledOrderId].quantity<=0){
                marketBuyOrders[filledOrderId] = buyOrder;
                orderIndex = filledOrderId;
            }else{
                marketBuyOrders.push(buyOrder);
                orderIndex = marketBuyOrders.length-1;
            }
        }

        emit OnPlaceBuyOrder(marketId, buyOrder.trader, orderIndex,
            price, quantity, buyOrder.quantity, lv.lastPrice, referrer);

    }

    function matchBuyOrder(
        uint256 marketId,
        Market storage market,
        Order memory buyOrder,
        uint256[] calldata sellOrderIDs,
        PlaceBuyOrderVariable memory lv
    ) private returns(uint256 totalTradeValue, uint256 lastPrice)
    {
        //matchBuyOrder
        totalTradeValue = 0;
        lastPrice = 0;
        uint256 length = sellOrderIDs.length;
        if(length==0) return (totalTradeValue, lastPrice);

        Order[] storage marketSellOrders = sellOrders[marketId];
        uint256 totalTradeQuantity = 0;
        for(uint256 i=0; i<length;){
            if(buyOrder.quantity<=0){
                break;
            }
            // uint256 sellOrderID = sellOrderIDs[i];
            Order storage sellOrder = marketSellOrders[sellOrderIDs[i]];
            uint256 sellOrderPrice = sellOrder.price;
            uint256 sellOrderQuantity = sellOrder.quantity;
            if (sellOrderPrice <= buyOrder.price && sellOrderQuantity>0) {

                uint256 tradeQuantity = Helper.min(buyOrder.quantity, sellOrderQuantity);
                uint256 tradeValue = sellOrderPrice * tradeQuantity / WAD;

                // storage
                // sub tradeQuantity
                sellOrder.quantity -= tradeQuantity;
                buyOrder.quantity -= tradeQuantity;
                // memory
                totalTradeQuantity += tradeQuantity;
                totalTradeValue += tradeValue;

                // credit (quote token) the seller's balance
                balances[sellOrder.trader][lv.quoteAddress] += tradeValue - _fee(tradeValue);
                lastPrice = sellOrderPrice;
            }
            unchecked{
                i++;
            }
        }
        if(totalTradeValue>0){
            // credit (base token) the buyer's balance
            balances[buyOrder.trader][lv.baseAddress] += totalTradeQuantity;

            //update geniPoints
            if(market.isRewardable){
                _updatePoints(lv.quoteAddress, buyOrder.trader, totalTradeValue);
            }

            // update market.price
            if(block.timestamp - market.lastUpdatePrice > 300){
                market.price = lastPrice;
                market.lastUpdatePrice = block.timestamp;
            }
        }
        return (totalTradeValue, lastPrice);
    }

    function getBuyOrders(uint256 marketId) public view returns (Order[] memory) {
        return buyOrders[marketId];
    }

    function getBuyOrders(
        uint256 marketId,
        uint256 minPrice
    ) public view returns (OutputOrder[] memory rsBuyOrders) {
        Order[] storage orders = buyOrders[marketId];
        uint256 totalOrders = orders.length;

        // Count matching orders first
        uint256 matchCount = 0;
        for (uint256 i = 0; i < totalOrders; i++) {
            if (orders[i].price >= minPrice) {
                matchCount++;
            }
        }

        // Allocate exact size
        rsBuyOrders = new OutputOrder[](matchCount);

        uint256 count = 0;
        for (uint256 j = 0; j < totalOrders; j++) {
            if (orders[j].price >= minPrice) {
                Order storage order = orders[j];
                rsBuyOrders[count] = OutputOrder({
                    id: j,
                    trader: order.trader,
                    price: order.price,
                    quantity: order.quantity
                });
                count++;
            }
        }
        return rsBuyOrders;
    }

    function cancelBuyOrder(
        uint256 marketId,
        uint256 orderIndex
    ) external nonReentrant whenNotPaused
    {
        //InvalidValue
        // Order[] storage marketOrders = buyOrders[marketId];
        address quoteAddress = markets[marketId].quoteAddress;

        // if(orderIndex >= marketOrders.length){
        //     revert Helper.InvalidValue({code: 'BO189', providedValue: orderIndex});
        // }

        Order storage order = buyOrders[marketId][orderIndex];
        address trader = order.trader;
        if (msg.sender != trader) {
            revert Helper.Unauthorized('BO186', msg.sender, trader);
        }
        uint256 quantity = order.quantity;
        if (quantity == 0) {
            revert Helper.OrderAlreadyCanceled('BO192', orderIndex);
        }
        uint256 total = quantity * order.price / WAD;
        order.quantity = 0;
        balances[trader][quoteAddress] += total + _fee(total);
    }

}