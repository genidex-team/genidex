// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

// suppress unused warning
contract Gas{
    
    uint256 ui256;

    constructor() {
    }

    function externalFunction() external{
        
    }

    function arrayInput(uint256 [] memory) external{
        
    }

    function publicFunction() public{
        
    }

    function withOneInput(uint256 number_) external{
        
    }

    function withAddressInput(address addr_) external{
        
    }

    uint256 number;
    function storeOneNumber(uint256 number_) external{
        number = number_;
    }

    address addr2;
    function storeOneAddress(address addr2_) external{
        addr2 = addr2_;
    }

    uint256 index = 1;
    mapping(uint256 => uint256) mapNumberNumber;
    function addNumberNumberToMap(uint256 key, uint256 number_) external{
        mapNumberNumber[key] = number_;
    }

    mapping(uint32 => uint256) mapUint32Number;
    function addUint32NumberToMap(uint32 key, uint256 number_) external{
        mapUint32Number[key] = number_;
    }

    uint256 number2;
    function readWriteNumberNumberMap(uint256 key) external{
        number2 = mapNumberNumber[key];
    }

    mapping(string => uint256) mapStringNumber;
    function addStringNumberToMap(string memory key, uint256 number_) external{
        mapStringNumber[key] = number_;
    }

    string str;
    function storeOneString(string memory str_) external{
        str = str_;
    }

    uint256 number3;
    function storeTwoNumbers(uint256 number_, uint256 number3_) external{
        number = number_;
        number3 = number3_;
    }

    uint256[] arrNumber;
    function pushElementToArray(uint256 number_) external{
        arrNumber.push(number_);
    }

    uint256 public maxUint256 = 2**256-1;
    uint8 public maxUint8 = 2**8-1;
    uint16 public maxUint16 = 2**16-1;
    uint32 public maxUint32 = 2**32-1;

    function noTransferFrom(address baseAddress, uint256 n) external {
    }

    function transferFrom(address baseAddress, uint256 n) external {
        IERC20 baseTokenContract = IERC20(baseAddress);

        for(uint256 i=0; i<n; i++){
            baseTokenContract.transferFrom(
                0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
                0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC,
                1000
            );
        }
    }

    uint256 aUint256;
    function updateUint256(uint256 n) external{
        for(uint256 i=0; i<n; i++){
            aUint256 = i;
        }
    }

    function updateUint256Memory(uint256 n) external{
        uint256 tmp;
        for(uint256 i=0; i<n; i++){
            tmp = i;
        }
        aUint256 = tmp;
    }

    function test() external pure returns(uint8 rs){
        int8 d = -18;
        rs = uint8(d);
    }

    struct Order1 {
        address trader;
        uint256 price;
        uint256 quantity;
    }
    struct Order2 {
        address trader;
        uint128 price;
        uint128 quantity;
    }
    struct Order3 {
        uint80 trader;
        uint80 price;
        uint80 quantity;
    }
    mapping(uint256 => Order1[]) public orders1;
    mapping(uint256 => Order2[]) public orders2;
    mapping(uint256 => Order3[]) public orders3;

    function addOrder1() external{
        Order1 memory buyOrder = Order1({
            trader: msg.sender,
            price: 100000,
            quantity: 100000
        });
        orders1[1].push(buyOrder);
    }

    function addOrder2() external{
        uint start = gasleft();
        for(uint256 i=0; i<100; i++){
            Order2 memory buyOrder = Order2({
                trader: msg.sender,
                price: 100000,
                quantity: 100000
            });
            orders2[1].push(buyOrder);
        }
        uint end = gasleft();
        console.log("\nGas used:", start - end);
    }

    function addOrder3() external{
        uint start = gasleft();
        for(uint256 i=0; i<100; i++){
            Order3 memory buyOrder = Order3({
                trader: 100000,
                price: 100000,
                quantity: 100000
            });
            orders3[1].push(buyOrder);
        }
        uint end = gasleft();
        console.log("\nGas used:", start - end);
    }
    
    function readOrder1() external view {
        uint start = gasleft();
        // Order3 storage buyOrder = orders3[1][0];
        // uint80 trader = orders3[1][0].trader;
        Order1 storage o1 = orders1[1][0];
        address trader = o1.trader;
        uint256 price = o1.price;
        uint256 quantity = o1.quantity;
        uint end = gasleft();
        console.log("\nGas used:", start - end);
        trader;
        price;
        quantity;
    }

    function readOrder2() external view{
        uint start = gasleft();
        for(uint256 i=0; i<100; i++){
            Order2 memory buyOrder = orders2[1][i];
            address trader = buyOrder.trader;
            uint128 price = buyOrder.price;
            uint128 quantity = buyOrder.quantity;
            buyOrder.quantity = 0;
            trader;
            price;
            quantity;
        }
        uint end = gasleft();
        console.log("\nGas used:", start - end);
    }

    function readOrder3() external view {
        // suppress unused warning
        uint start = gasleft();
        for(uint256 i=0; i<100; i++){
            Order3 memory buyOrder = orders3[1][i];
            uint80 trader = buyOrder.trader;
            uint80 price = buyOrder.price;
            uint80 quantity = buyOrder.quantity;
            buyOrder.quantity = 0;
            trader;
            price;
            quantity;
        }
        uint end = gasleft();
        console.log("\nGas used:", start - end);
    }

    mapping(address => mapping(address => uint256)) public balances1; // balances1[account][token]
    mapping(address => mapping(address => uint128)) public balances2;

    function addBalance1() external{
        balances1[msg.sender][0x73511669fd4dE447feD18BB79bAFeAC93aB7F31f] = 1000;
    }

    function addBalance2() external{
        balances2[msg.sender][0x73511669fd4dE447feD18BB79bAFeAC93aB7F31f] = 1000;
    }
}