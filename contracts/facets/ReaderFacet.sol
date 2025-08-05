// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../Storage.sol";

contract ReaderFacet {
    using Storage for *;

    function getReader() external view returns(address){
        Storage.CoreConfig storage c = Storage.core();
        return c.reader;
    }

    function getFilledOrders(
        uint8 orderType,
        uint256 marketID,
        uint256 limit
    ) external view returns (uint256[] memory) {
        Storage.MarketData storage m = Storage.market();
        Storage.Order[] storage list;
        if(orderType==0){
            list = m.buyOrders[marketID];
        }else{
            list = m.sellOrders[marketID];
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
        uint8 orderType,
        uint256 marketID,
        uint256 offset,
        uint256 limit
    ) external view returns (Storage.OutputOrder[] memory orders) {
        Storage.UserData storage u = Storage.user();
        Storage.MarketData storage m = Storage.market();
        Storage.Order[] storage list;
        if(orderType==0){
            list = m.buyOrders[marketID];
        }else{
            list = m.sellOrders[marketID];
        }
        uint256 len = list.length;

        if (offset >= len) {
            // Offset exceeds array length → return empty array
            return new Storage.OutputOrder[](0);
        }

        // Calculate the end index without exceeding the array length
        uint256 end = offset + limit;
        if (end > len) {
            end = len;
        }

        uint256 size = end - offset;
        orders = new Storage.OutputOrder[](size);

        // Copy each element from storage into memory
        for (uint256 i; i < size; ++i) {
            Storage.Order storage order = list[offset + i];
            uint80 userID = order.userID;
            orders[i] = Storage.OutputOrder({
                id: offset + i,
                trader: u.userAddresses[userID],
                userID: userID,
                price: order.price,
                quantity: order.quantity
            });
        }
    }

    /// @notice Return the total number of buy orders for a market
    function getBuyOrdersLength(uint256 marketID) external view returns (uint256) {
        Storage.MarketData storage m = Storage.market();
        return m.buyOrders[marketID].length;
    }

    /// @notice Return the total number of sell orders for a market
    function getSellOrdersLength(uint256 marketID) external view returns (uint256) {
        Storage.MarketData storage m = Storage.market();
        return m.sellOrders[marketID].length;
    }

    function getBalance(address account, address tokenOrEtherAddress) external view returns (uint256){
        Storage.UserData storage u = Storage.user();
        uint80 userID = u.userIDs[account];
        return u.balances[userID][tokenOrEtherAddress];
    }

    function getEthBalance() external view returns (uint256){
        Storage.UserData storage u = Storage.user();
        uint80 userID = u.userIDs[msg.sender];
        return u.balances[userID][address(0)];
    }

    // market

    function getMarketID(address baseAddress, address quoteAddress) external view returns(uint256){
        Storage.MarketData storage m = Storage.market();
        bytes32 hash = keccak256(abi.encodePacked(baseAddress, quoteAddress));
        return m.marketIDs[hash];
    }

    function getMarket(uint256 id) external view returns(Storage.Market memory) {
        Storage.MarketData storage m = Storage.market();
        return m.markets[id];
    }

    function getAllMarkets() external view returns(Storage.Market[] memory) {
        Storage.MarketData storage m = Storage.market();
        Storage.Market[] memory outputMarkets = new Storage.Market[](m.marketCounter);
        for(uint256 i=1; i<=m.marketCounter; i++){
            outputMarkets[i-1] = m.markets[i];
        }
        return outputMarkets;
    }

    //referral

    function getReferees(
        address referrer
    ) external view returns (address[] memory) {
        Storage.UserData storage u = Storage.user();
        return u.refereesOf[referrer];
    }

    function getReferrer(
        address referee
    ) external view returns (address) {
        Storage.UserData storage u = Storage.user();
        return u.userReferrer[referee];
    }

    // Token
    struct TokenInfo {
        address tokenAddress;
        string symbol;
        uint80 usdMarketID;
        uint80 minOrderAmount;
        uint80 minTransferAmount;
        uint8 decimals;
        bool isUSD;
    }

    function getTokensInfo(address[] calldata tokenAddresses) external view returns (TokenInfo[] memory) {
        Storage.TokenData storage t = Storage.token();
        uint256 length = tokenAddresses.length;
        TokenInfo[] memory result = new TokenInfo[](length);
        for (uint256 i = 0; i < length; i++) {
            Storage.Token memory info = t.tokens[tokenAddresses[i]];
            result[i] = TokenInfo({
                tokenAddress: tokenAddresses[i],
                symbol: info.symbol,
                usdMarketID: info.usdMarketID,
                minOrderAmount: info.minOrderAmount,
                minTransferAmount: info.minTransferAmount,
                decimals: info.decimals,
                isUSD: info.isUSD
            });
        }
        return result;
    }

}