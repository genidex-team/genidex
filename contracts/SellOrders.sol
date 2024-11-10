
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./Storage.sol";
import "./Points.sol";
import "./Helper.sol";


abstract contract SellOrders is Storage, Points{
    
    using Math for uint256;

    event OnPlaceSellOrder(
        uint256 indexed marketId,
        address indexed trader,
        uint256 orderIndex,
        uint256 price,
        uint256 quantity,
        uint256 remainingQuantity,
        uint256 lastPrice
    );
    /*struct InputPlaceSellOrder {
        uint256 marketId;
        uint256 price;
        uint256 quantity;
        uint256 filledOrderId;
    }*/
    struct PlaceSellOrderVariable{
        address baseAddress;
        address quoteAddress;
        uint256 marketDecimalsPower;
        uint256 total;
    }
    function placeSellOrder(uint256 marketId, uint256 price, uint256 quantity,
        uint256 filledOrderId, uint256[] calldata buyOrderIDs) external {
        Market storage market = markets[marketId];
        //lv: local variable
        PlaceSellOrderVariable memory lv = PlaceSellOrderVariable({
            baseAddress: market.baseAddress,
            quoteAddress: market.quoteAddress,
            marketDecimalsPower: market.marketDecimalsPower,
            total: 0
        });

        lv.total = price * quantity / lv.marketDecimalsPower;
        if (lv.total < 1) {
            revert Helper.TotalTooSmall('SO49', lv.total, 1);
        }

        Order memory sellOrder = Order({
            trader: msg.sender,
            price: price,
            quantity: quantity
        });

        mapping(address => uint256) storage sellerBalances = balances[sellOrder.trader];
        if(sellerBalances[lv.baseAddress] < quantity){
            revert Helper.InsufficientBalance({
                code: 'SO58',
                available: sellerBalances[lv.baseAddress],
                required: quantity
            });
        }

        Order[] storage marketSellOrders = sellOrders[marketId];
        // Order[] storage marketBuyOrders = buyOrders[marketId];

        uint256 lastPrice = matchSellOrder(marketId, market, sellOrder, buyOrderIDs, lv);
        sellerBalances[lv.baseAddress] -= quantity;

        uint256 remainingValue = price * sellOrder.quantity / lv.marketDecimalsPower;
        if(remainingValue>0){
            if(filledOrderId < marketSellOrders.length && marketSellOrders[filledOrderId].quantity<=0){
                marketSellOrders[filledOrderId] = sellOrder;
                emit OnPlaceSellOrder(marketId, sellOrder.trader, filledOrderId,
                    price, quantity, sellOrder.quantity, lastPrice);
            }else{
                marketSellOrders.push(sellOrder);
                emit OnPlaceSellOrder(marketId, sellOrder.trader, marketSellOrders.length-1,
                    price, quantity, sellOrder.quantity, lastPrice);
            }
        }else{
            emit OnPlaceSellOrder(marketId, sellOrder.trader, 0,
                price, quantity, sellOrder.quantity, lastPrice);
        }
    }

    function matchSellOrder(uint256 marketId, Market storage market, Order memory sellOrder, uint256[] calldata buyOrderIDs,
        PlaceSellOrderVariable memory lv)
        private returns(uint256 lastPrice){

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
            if (buyOrder.price >= sellOrder.price && buyOrder.quantity>0) {

                uint256 tradeQuantity = Helper.min(buyOrder.quantity, sellOrder.quantity);
                uint256 tradeValue = buyOrder.price * tradeQuantity / lv.marketDecimalsPower;

                buyOrder.quantity -= tradeQuantity;
                sellOrder.quantity -= tradeQuantity;

                // totalTradeQuantity += tradeQuantity;
                totalTradeValue += tradeValue;

                balances[buyOrder.trader][lv.baseAddress] += tradeQuantity;
                lastPrice = buyOrder.price;
            }
            unchecked{
                i++;
            }
        }
        if(totalTradeValue>0){
            uint256 totalFee = fee(totalTradeValue);
            balances[sellOrder.trader][lv.quoteAddress] += (totalTradeValue - totalFee);
            balances[feeReceiver][lv.quoteAddress] += 2*totalFee;

            //update geniPoints
            if(market.isRewardable == true){
                updatePoints(lv.quoteAddress, sellOrder.trader, totalTradeValue);
            }
        }
        return lastPrice;
    }

    function getSellOrders(uint256 marketId) public view returns (Order[] memory) {
        return sellOrders[marketId];
    }

    function cancelSellOrder(uint256 marketId, uint256 orderIndex) public{
        
        // Order[] storage marketOrders = sellOrders[marketId];
        address baseAddress = markets[marketId].baseAddress;

        // if(orderIndex >= marketOrders.length){
        //     revert Helper.InvalidValue({code: 'SO159', providedValue: orderIndex});
        // }

        Order storage order = sellOrders[marketId][orderIndex];
        address trader = order.trader;
        if (msg.sender != trader) {
            revert Helper.Unauthorized('SO165', msg.sender);
        }
        uint256 quantity = order.quantity;
        if (quantity == 0) {
            revert Helper.OrderAlreadyCanceled('SO169', orderIndex);
        }
        order.quantity = 0;
        balances[trader][baseAddress] += quantity;
    }

}