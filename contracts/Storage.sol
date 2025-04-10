// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardTransientUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Helper} from "./Helper.sol";

abstract contract Storage is Initializable, ReentrancyGuardTransientUpgradeable {
    struct Market {
        uint256 id;
        string symbol;
        address baseAddress;
        address quoteAddress; //ERC20 token address for the quote asset (e.g., stablecoin)
        uint256 price;
        uint256 lastUpdatePrice;
        uint256 marketDecimalsPower;
        uint8 marketDecimals;
        uint8 priceDecimals;
        uint8 totalDecimals;
        bool isRewardable;
    }

    uint256 public marketCounter;

    /**
     * Key: bytes32 hash = keccak256(abi.encodePacked(baseAddress, quoteAddress));
     * Value: marketCounter++
     * ex: marketIDs[hash] = marketCounter++;
     */
    mapping(bytes32 => uint256) public marketIDs;

    /**
     * Key: marketCounter++
     * Value: Market({...})
     * ex: markets[marketCounter++] = Market({...});
     * */
    mapping(uint256 => Market) public markets;

    struct Order {
        address trader;
        uint256 price;
        uint256 quantity;
        // uint256 orderIndex;
        // bool isActive;
    }

    // mapping(marketID => Order)
    mapping(uint256 => Order[]) public buyOrders;
    mapping(uint256 => Order[]) public sellOrders;

    // mapping(address => uint256) public ethBalances;
    // balances[userAddress][tokenAddress]
    mapping(address => mapping(address => uint256)) balances;

    // mapping(address => bool) public usdTokens;
    // mapping(address => uint256) public tokenPriceInUSD;

    struct Token {
        bool isUSD;
        uint8 decimals;
        uint256 usdMarketID;
    }

    mapping(address => Token) public tokens;

    mapping(address => uint256) public userPoints;
    uint256 public totalUnclaimedPoints;
    mapping(address => address) public userReferrer; // referral => referrer
    mapping(address => address[]) public refereesOf; // referrer => [referees]

    address public constant feeReceiver = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;

    address public geniRewarder;

    function __Storage_init() internal onlyInitializing {
        marketCounter = 0;
        totalUnclaimedPoints = 0;
    }

    function fee(uint256 amount) internal pure returns (uint256 result) {
        // result = amount*percentageFee/feeDecimalsPower;
        // 0.1% = 0.001 = 1/1000
        result = amount / 1000;
    }

    function setReferrer(address _referrer) external {
        require(userReferrer[msg.sender] == address(0), "Referrer already set");
        require(_referrer != address(0), "Invalid referrer address");
        require(_referrer != msg.sender, "Cannot refer yourself");
        userReferrer[msg.sender] = _referrer;
        refereesOf[_referrer].push(msg.sender);
    }
}
