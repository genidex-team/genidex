// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Storage.sol";
import {Helper} from "./Helper.sol";

abstract contract CancelOrders is Storage {
    // event OrderCancelled(
    //     uint256 indexed marketId,
    //     address account
    // );

    function cancelBuyOrder1(uint256 marketId, uint256 orderIndex, bool isBuyOrder) external {
        Order[] storage marketOrders = isBuyOrder ? buyOrders[marketId] : sellOrders[marketId];
        address baseTokenAddress = markets[marketId].baseAddress;
        address quoteTokenAddress = markets[marketId].quoteAddress;
        uint8 marketDecimals = markets[marketId].marketDecimals;

        require(orderIndex < marketOrders.length, "Invalid order index");
        Order storage order = marketOrders[orderIndex];
        require(
            order.trader == msg.sender,
            "Only the creator can cancel this order"
        );

        require(
            order.quantity != 0,
            "Insufficient balance to refund"
        );

        if (isBuyOrder) {
            uint256 amount = order.quantity * order.price/ (10**marketDecimals);
            buyOrders[marketId][orderIndex].quantity = 0;
            // payable(msg.sender).transfer(amount); // Hoàn trả Ether
            IERC20(quoteTokenAddress).transfer(msg.sender, amount);
            // if (tokenAddress == address(0)) {
            //     // Trường hợp người dùng đã lock Ether
            //     (bool sent, ) = order.trader.call{value: order.quantity}("");
            //     require(sent, "Failed to send Ether");
            // } else {
            //     // Trường hợp token được sử dụng cho lệnh mua (hoàn trả lại token)
            //     IERC20(tokenAddress).transfer(order.trader, order.quantity);
            // }
        } else {
            uint256 quantity = order.quantity;
            sellOrders[marketId][orderIndex].quantity=0;
            IERC20(baseTokenAddress).transfer(msg.sender, quantity);
        }

        // emit OrderCancelled(marketId, msg.sender);
    }
}
