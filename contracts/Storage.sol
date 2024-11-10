// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Helper} from "./Helper.sol";

abstract contract Storage is Initializable {
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

    address public geniTokenAddress;

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
    mapping(address => mapping(address => uint256)) balances;

    // mapping(address => bool) public usdTokens;
    // mapping(address => uint256) public tokenPriceInUSD;

    struct Token {
        bool isUSD;
        uint8 decimals;
        uint256 usdMarketID;
    }

    mapping(address => Token) public tokens;

    // struct User {
    //     uint256 geniPoints;
    // }
    mapping(address => uint256) public geniPoints;
    uint256 public totalPoints;

    uint256 public percentageFee;
    uint256 public feeDecimals;
    uint256 public feeDecimalsPower;
    address public feeReceiver;

    function __Storage_init() internal onlyInitializing {
        percentageFee = 100; //100/100,000*100 = 0.1%
        feeDecimals = 5;
        feeDecimalsPower = 10 ** feeDecimals;
        feeReceiver = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
        totalPoints = 0;
    }

    function fee(uint256 amount) internal pure returns (uint256 result) {
        // result = amount*percentageFee/feeDecimalsPower;
        // 0.1% = 0.001 = 1/1000
        result = amount / 1000;
    }

    // Assign the GeniToken address, can only be called once
    function setGeniTokenAddress(address _geniTokenAddress) external {
        require(
            geniTokenAddress == address(0),
            "GeniToken address has been set"
        );
        geniTokenAddress = _geniTokenAddress;
    }

    // Modifier to restrict this function to be callable only by the GeniToken contract
    modifier onlyGeniTokenContract() {
        require(
            msg.sender == geniTokenAddress,
            "Only the GeniToken contract can call this function"
        );
        _;
    }

    // Function to subtract points from the total points
    function deductTotalPoints(uint256 points) external onlyGeniTokenContract {
        require(
            points <= totalPoints,
            "Cannot subtract more than the current total points"
        );
        totalPoints -= points;
    }
}
