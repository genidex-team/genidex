// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardTransientUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./Storage.sol";
import "./Helper.sol";

abstract contract GeniDexBase is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardTransientUpgradeable,
    Storage
{
    using Helper for address;

    function __GeniDexBase_init(address initialOwner) internal onlyInitializing {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        __Pausable_init();
        __ReentrancyGuardTransient_init();
        __Storage_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function __Storage_init() internal onlyInitializing {
        marketCounter = 0;
        totalUnclaimedPoints = 0;
    }

    function _fee(uint256 amount) internal pure returns (uint256 result) {
        // 0.1% = 0.001 = 1/1000
        result = amount / 1000;
    }

    function _updatePoints(
        address quoteAddress,
        uint80 userID,
        uint256 totalTradeValue
    ) internal {
        Token storage quoteToken = tokens[quoteAddress];
        uint256 points = 0;
        if(quoteToken.isUSD){
            points = totalTradeValue;
        }else if(quoteToken.usdMarketID != 0){
            Market storage usdMarket = markets[quoteToken.usdMarketID];
            points = usdMarket.price * totalTradeValue / WAD;
        }
        if(points > 0){
            userPoints[userID] += points;
            totalUnclaimedPoints += points;

            /*address ref = userReferrer[traderAddress];
            if (ref != address(0)) {
                uint256 refPoints = points * 30 / 100;
                userPoints[ref] += refPoints;
                totalUnclaimedPoints += refPoints;
            }*/
        }
    }

    /**
     * Fetch symbol and decimals of a token and cache them if not already stored.
     *
     * @param tokenAddress The address of the ERC20 token.
     * @return symbol The token's symbol.
     * @return decimals The token's decimals.
    */
    function getAndSetTokenMeta(address tokenAddress) public returns (string memory symbol, uint8 decimals) {
        // If already cached, return from storage
        Token storage info = tokens[tokenAddress];
        if (bytes(info.symbol).length > 0) {
            return (info.symbol, info.decimals);
        }

        // Otherwise, fetch from token contract
        if(tokenAddress == address(0)){
            symbol = 'ETH';
            decimals = 18;
        } else {
            symbol = tokenAddress.getSymbol();
            decimals = tokenAddress.getDecimals();
        }
        tokens[tokenAddress].symbol = symbol;
        tokens[tokenAddress].decimals = decimals;

        return (symbol, decimals);
    }
}