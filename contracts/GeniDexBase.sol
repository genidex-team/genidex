// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardTransientUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./Storage.sol";
import "./Helper.sol";

abstract contract GeniDexBase is
    Initializable,
    AccessControlDefaultAdminRulesUpgradeable,
    UUPSUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardTransientUpgradeable,
    Storage
{
    event FeeReceiverUpdated(address indexed oldAddress, address indexed newAddress);
    // using Helper for address;

    function __GeniDexBase_init(address initialOwner) internal onlyInitializing {
        __AccessControlDefaultAdminRules_init(7 days, initialOwner);
        __UUPSUpgradeable_init();
        __Pausable_init();
        __ReentrancyGuardTransient_init();
        __Storage_init(initialOwner);
        _grantRole(UPGRADER_ROLE,       initialOwner);
        _grantRole(PAUSER_ROLE,         initialOwner);
        _grantRole(OPERATOR_ROLE,       initialOwner);
        _grantRole(FEE_MANAGER_ROLE,    initialOwner);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function __Storage_init(address initialOwner) internal onlyInitializing {
        marketCounter = 0;
        totalUnclaimedPoints = 0;
        // feeReceiver
        _generateUserID(initialOwner);
    }

    function _generateUserID(address userAddress) internal returns(uint80){
        uint80 userID = userIDs[userAddress];
        if(userID>0){
            return userID;
        }else{
            userID = ++userCounter;
            userAddresses[userID] = userAddress;
            userIDs[userAddress] = userID;
            return userID;
        }
    }

    function updateFeeReceiver(address newAddr) external onlyRole(FEE_MANAGER_ROLE) {
        if (newAddr == address(0)) revert Helper.InvalidAddress();
        if (userIDs[newAddr] != 0) revert Helper.AddressAlreadyLinked();

        address oldAddr = userAddresses[FEE_USER_ID];

        userAddresses[FEE_USER_ID] = newAddr;
        userIDs[newAddr]           = FEE_USER_ID;

        delete userIDs[oldAddr];

        emit FeeReceiverUpdated(oldAddr, newAddr);
    }

    function _fee(uint256 amount) internal pure returns (uint256 result) {
        // amount*0.1% = amount*0.001 = amount/1000
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
            points = usdMarket.price * totalTradeValue / BASE_UNIT;
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

    function _getTokenMeta(address tokenAddress) internal view returns (string memory symbol, uint8 decimals) {
        Token storage info = tokens[tokenAddress];
        if(!isTokenListed[tokenAddress]){
            revert Helper.TokenNotListed(tokenAddress);
        }
        return (info.symbol, info.decimals);
    }

}