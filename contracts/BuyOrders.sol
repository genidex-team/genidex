
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./Storage.sol";
import "./Points.sol";
import "./Helper.sol";

abstract contract BuyOrders is Storage, Points{
    // using Math for uint256;
    // using Helper for uint256;

    event OnPlaceBuyOrder(
        uint256 indexed marketId,
        address indexed trader,
        uint256 orderIndex,
        uint256 price,
        uint256 quantity,
        uint256 remainingQuantity,
        uint256 lastPrice
    );

    // event OnMatchBuyOrder(
    //     uint256 indexed marketId,
    //     uint256 price,
    //     uint256 quantity
    // );
    /*struct InputOrder {
        uint256 marketId;
        uint256 price;
        uint256 quantity;
        uint256 filledOrderId;
    }*/
    
    struct PlaceBuyOrderVariable {
        address baseAddress;
        address quoteAddress;
        uint256 marketDecimalsPower;
        uint256 total;
        uint256 totalTradeValue;
        uint256 totalValue;
        uint256 lastPrice;
    }
    function placeBuyOrder(uint256 marketId, uint256 price, uint256 quantity,
        uint256 filledOrderId, uint256[] calldata sellOrderIDs) external {
        Market storage market = markets[marketId];
        //lv: local variable
        PlaceBuyOrderVariable memory lv = PlaceBuyOrderVariable({
            baseAddress: market.baseAddress,
            quoteAddress: market.quoteAddress,
            marketDecimalsPower: market.marketDecimalsPower,
            total: 0,
            totalTradeValue: 0,
            totalValue: 0,
            lastPrice: 0
        });

        Order memory buyOrder = Order({
            trader: msg.sender,
            price: price,
            quantity: quantity
        });
        lv.total = price * quantity / lv.marketDecimalsPower;
        if (lv.total < 1) {
            revert Helper.TotalTooSmall('BO68', lv.total, 1);
        }

        mapping(address => uint256) storage buyerBalances = balances[buyOrder.trader];
        if(buyerBalances[lv.quoteAddress] < lv.total){
            revert Helper.InsufficientBalance({
                code: 'BO73',
                available: buyerBalances[lv.quoteAddress],
                required:lv.total
            });
        }

        (lv.totalTradeValue, lv.lastPrice) = matchBuyOrder(marketId, market, buyOrder, sellOrderIDs, lv);
        uint256 remainingValue = price * buyOrder.quantity / lv.marketDecimalsPower;
        lv.totalValue = lv.totalTradeValue + remainingValue;

        //debit the buyOrder's balance
        buyerBalances[lv.quoteAddress] -= lv.totalValue + fee(lv.totalValue);

        //credit the feeReceiver's balance
        balances[feeReceiver][lv.quoteAddress] += 2 * fee(lv.totalTradeValue); // seller fee + buyer fee = 2*fee(lv.totalTradeValue)

        //  Order[] storage marketSellOrders = sellOrders[marketId];
        Order[] storage marketBuyOrders = buyOrders[marketId];

        uint256 orderIndex = 0;
        if(remainingValue>0){
            if(filledOrderId < marketBuyOrders.length && marketBuyOrders[filledOrderId].quantity<=0){
                marketBuyOrders[filledOrderId] = buyOrder;
                orderIndex = filledOrderId;
            }else{
                marketBuyOrders.push(buyOrder);
                orderIndex = marketBuyOrders.length-1;
            }
        }
        emit OnPlaceBuyOrder(marketId, buyOrder.trader, orderIndex,
            price, quantity, buyOrder.quantity, lv.lastPrice);

    }

    function matchBuyOrder(uint256 marketId, Market storage market, Order memory buyOrder,
        uint256[] calldata sellOrderIDs, PlaceBuyOrderVariable memory lv) private
        returns(uint256 totalTradeValue, uint256 lastPrice)
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
                uint256 tradeValue = sellOrderPrice * tradeQuantity / lv.marketDecimalsPower;

                // storage
                // sub tradeQuantity
                sellOrder.quantity -= tradeQuantity;

                // memory
                totalTradeQuantity += tradeQuantity;
                totalTradeValue += tradeValue;

                // credit (quote token) the seller's balance
                balances[sellOrder.trader][lv.quoteAddress] += tradeValue - fee(tradeValue);
                lastPrice = sellOrderPrice;
            }
            unchecked{
                i++;
            }
        }
        if(totalTradeValue>0){
            buyOrder.quantity -= totalTradeQuantity;
            // credit (base token) the buyer's balance
            balances[buyOrder.trader][lv.baseAddress] += totalTradeQuantity;

            //update geniPoints
            if(market.isRewardable == true){
                updatePoints(lv.quoteAddress, buyOrder.trader, totalTradeValue);
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

    function cancelBuyOrder(uint256 marketId, uint256 orderIndex) public{
        //InvalidValue
        // Order[] storage marketOrders = buyOrders[marketId];
        address quoteAddress = markets[marketId].quoteAddress;
        uint256 marketDecimalsPower = markets[marketId].marketDecimalsPower;

        // if(orderIndex >= marketOrders.length){
        //     revert Helper.InvalidValue({code: 'BO189', providedValue: orderIndex});
        // }

        Order storage order = buyOrders[marketId][orderIndex];
        address trader = order.trader;
        if (msg.sender != trader) {
            revert Helper.Unauthorized('BO186', msg.sender);
        }
        uint256 quantity = order.quantity;
        if (quantity == 0) {
            revert Helper.OrderAlreadyCanceled('BO192', orderIndex);
        }
        uint256 total = quantity * order.price / marketDecimalsPower;
        order.quantity = 0;
        balances[trader][quoteAddress] += total + fee(total);
    }

}