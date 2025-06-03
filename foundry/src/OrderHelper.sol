// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {GeniDex} from "./GeniDexHelper.sol";

struct Order {
    address trader;
    uint256 price;
    uint256 quantity;
}

library OrderHelper {

    function getSellOrderIDs(GeniDex dex, uint256 marketId, uint256 maxPrice)
        public view returns (uint256[] memory)
    {
        GeniDex.OutputOrder[] memory tmpSellOrders = dex.getSellOrders(marketId, maxPrice);
        GeniDex.OutputOrder[] memory sellOrders = sortSellOrders(tmpSellOrders);
        uint256[] memory sellOrderIDs;
        uint256 length = sellOrders.length;
        uint256 i;
        for(i=0; i < length; i++){
            sellOrderIDs[i] = sellOrders[i].id;
        }
        return sellOrderIDs;
    }

     function sortSellOrders(GeniDex.OutputOrder[] memory sellOrders)
        public pure returns (GeniDex.OutputOrder[] memory)
    {
        if (sellOrders.length > 1) {
            _quickSort(sellOrders, 0, int(sellOrders.length - 1));
        }
        return sellOrders;
    }

    function _quickSort(GeniDex.OutputOrder[] memory arr, int left, int right) internal pure {
        int i = left;
        int j = right;

        if (i == j) return;

        uint pivot = arr[uint(left + (right - left) / 2)].price;
        while (i <= j) {
            while (arr[uint(i)].price < pivot) i++;
            while (pivot < arr[uint(j)].price) j--;
            if (i <= j) {
                // Swap elements at i and j
                GeniDex.OutputOrder memory temp = arr[uint(i)];
                arr[uint(i)] = arr[uint(j)];
                arr[uint(j)] = temp;
                i++;
                j--;
            }
        }

        if (left < j)
            _quickSort(arr, left, j);
        if (i < right)
            _quickSort(arr, i, right);
    }

}
