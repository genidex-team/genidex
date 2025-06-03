// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./GeniDexBase.sol";

abstract contract Markets is GeniDexBase {

    function addMarket(
        address baseAddress, address quoteAddress, uint256 minOrderAmount
    ) external onlyOwner {
        string memory baseSymbol;
        string memory quoteSymbol;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        (baseSymbol, baseDecimals) = getAndSetTokenMeta(baseAddress);
        (quoteSymbol, quoteDecimals) = getAndSetTokenMeta(quoteAddress);
        if(minOrderAmount>0 && tokens[quoteAddress].minOrderAmount==0){
            tokens[quoteAddress].minOrderAmount = minOrderAmount;
        }

        bytes32 hash = generateMarketHash(baseAddress, quoteAddress);
        require(marketIDs[hash]==0, 'Market already exists.');
        marketCounter++;

        markets[marketCounter] = Market({
            symbol: string(abi.encodePacked(baseSymbol, '_', quoteSymbol)),
            id: marketCounter,
            price: 0,
            lastUpdatePrice: 0,
            baseAddress: baseAddress,
            quoteAddress: quoteAddress,
            creator: msg.sender,
            isRewardable: false
        });
        marketIDs[hash] = marketCounter;

    }

    function getMarketID(address baseAddress, address quoteAddress) external view returns(uint256){
        bytes32 hash = generateMarketHash(baseAddress, quoteAddress);
        return marketIDs[hash];
    }

    function getMarket(uint256 id) external view returns(Market memory) {
        return markets[id];
    }

    function generateMarketHash(address baseAddress, address quoteAddress) public pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(baseAddress, quoteAddress));
        return hash;
    }

    function getAllMarkets() external view returns(Market[] memory) {
        Market[] memory outputMarkets = new Market[](marketCounter);
        for(uint256 i=1; i<=marketCounter; i++){
            outputMarkets[i-1] = markets[i];
        }
        return outputMarkets;
    }

    function updateMarketIsRewardable(uint256 marketId, bool isRewardable) public onlyOwner() {
        markets[marketId].isRewardable = isRewardable;
    }

}