
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
            revert Helper.InvalidMarketId(marketId, marketCounter);
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
            revert Helper.TotalTooSmall(lv.total, tokens[lv.quoteAddress].minOrderAmount);
        }

        mapping(address => uint256) storage buyerBalances = balances[buyOrder.trader];
        if(buyerBalances[lv.quoteAddress] < lv.total + _fee(lv.total)){
            revert Helper.InsufficientBalance({
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

    function cancelBuyOrder(
        uint256 marketId,
        uint256 orderIndex
    ) external nonReentrant whenNotPaused
    {
        //InvalidValue
        // Order[] storage marketOrders = buyOrders[marketId];
        address quoteAddress = markets[marketId].quoteAddress;

        // if(orderIndex >= marketOrders.length){
        //     revert Helper.InvalidValue({providedValue: orderIndex});
        // }

        Order storage order = buyOrders[marketId][orderIndex];
        address trader = order.trader;
        if (msg.sender != trader) {
            revert Helper.Unauthorized(msg.sender, trader);
        }
        uint256 quantity = order.quantity;
        if (quantity == 0) {
            revert Helper.OrderAlreadyCanceled(orderIndex);
        }
        uint256 total = quantity * order.price / WAD;
        order.quantity = 0;
        balances[trader][quoteAddress] += total + _fee(total);
    }

    function getFilledOrders(
        OrderType orderType,
        uint256 marketID,
        uint256 limit
    ) external view returns (uint256[] memory) {
        Order[] storage list;
        if(orderType==OrderType.Buy){
            list = buyOrders[marketID];
        }else{
            list = sellOrders[marketID];
        }
        uint256 len = list.length;
        uint256 count = 0;
        for (uint256 i=0; i < len; i++) {
            if(list[i].quantity==0){
                count++;
                if(count>limit) break;
            }
        }
        uint256[] memory result = new uint256[](count);
        uint256 j = 0;

        for (uint256 i = 0; i < len; i++) {
            if (list[i].quantity == 0) {
                result[j] = i;
                j++;
                if(count>limit) break;
            }
        }

        return result;
    }

    /**
     * @notice Retrieve buy orders of `marketID` with pagination.
     * @param marketID   The market identifier.
     * @param offset     Index of the first element to return (0-based).
     * @param limit      Maximum number of elements to return.
     * @return orders    Array of Order with length <= limit.
     */
    function getOrders(
        OrderType orderType,
        uint256 marketID,
        uint256 offset,
        uint256 limit
    ) external view returns (Order[] memory orders) {
        Order[] storage list;
        if(orderType==OrderType.Buy){
            list = buyOrders[marketID];
        }else{
            list = sellOrders[marketID];
        }
        uint256 len = list.length;

        if (offset >= len) {
            // Offset exceeds array length → return empty array
            return new Order[](0);
        }

        // Calculate the end index without exceeding the array length
        uint256 end = offset + limit;
        if (end > len) {
            end = len;
        }

        uint256 size = end - offset;
        orders = new Order[](size);

        // Copy each element from storage into memory
        for (uint256 i; i < size; ++i) {
            orders[i] = list[offset + i];
        }
    }

    /// @notice Return the total number of buy orders for a market
    function getBuyOrdersLength(uint256 marketID) external view returns (uint256) {
        return buyOrders[marketID].length;
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

}