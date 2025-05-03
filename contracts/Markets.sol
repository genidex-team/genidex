// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./Storage.sol";

abstract contract Markets is Storage {

    function addMarket(address baseAddress, address quoteAddress) external {
        uint8 baseDecimals;
        uint8 quoteDecimals;
        string memory baseSymbol;
        string memory quoteSymbol;
        if(baseAddress == address(0)){ // ETH
            baseDecimals = 18;
            baseSymbol = 'ETH';
        }else{
            Token storage sBaseToken = tokens[baseAddress];
            if(sBaseToken.decimals == 0){
                ERC20 baseToken = ERC20(baseAddress);
                baseDecimals = baseToken.decimals();
                baseSymbol = baseToken.symbol();

                sBaseToken.decimals = baseDecimals;
                sBaseToken.symbol = baseSymbol;
            }else{
                baseDecimals = sBaseToken.decimals;
                baseSymbol = sBaseToken.symbol;
            }
        }
        if(quoteAddress == address(0)){ // ETH
            quoteDecimals = 18;
            quoteSymbol = 'ETH';
        }else{
            Token storage sQuoteToken = tokens[quoteAddress];
            if(sQuoteToken.decimals == 0){
                ERC20 quoteToken = ERC20(quoteAddress);
                quoteDecimals = quoteToken.decimals();
                quoteSymbol = quoteToken.symbol();

                sQuoteToken.decimals = quoteDecimals;
                sQuoteToken.symbol = quoteSymbol;
            }else{
                quoteDecimals = sQuoteToken.decimals;
                quoteSymbol = sQuoteToken.symbol;
            }
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