// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {GeniDex, GeniDexHelper} from "../src/GeniDexHelper.sol";
import "../contracts/test/TestToken.sol";
import "../src/OrderHelper.sol";

contract DepositEth_Fuzz is Test {
    GeniDex dex;
    TestToken internal quoteToken;
    TestToken internal baseToken;
    address internal alice = address(0xA11CE);
    uint256 internal constant WAD = 10**18;
    uint256 marketId = 1;

    function setUp() public {
        dex = GeniDexHelper.deploy();

        quoteToken =  new TestToken('USDT', 'USDT', 1_000_000_000*10**6, 6);
        dex.updateTokenIsUSD(address(quoteToken), true);
        baseToken =   new TestToken('OP', 'OP', 1_000_000_000*10**18, 18);
        dex.addMarket(address(baseToken), address(quoteToken));

        alice = payable(vm.addr(1));

        vm.startPrank(alice);

        // deposit
        uint256 amount = 10**72;
        quoteToken.mint(amount);
        quoteToken.approve(address(dex), amount);
        dex.depositToken(address(quoteToken), amount);

        // GeniDexHelper.placeBuyOrder(dex, marketId, 1*WAD, 5*WAD);
        vm.stopPrank();
    }

    function testFuzz_PlaceBuyOrder(uint256 price, uint256 quantity) public {
        vm.assume(price < 10**36 && quantity < 10**36);
        uint256 total = price * quantity / WAD;
        vm.assume(0 < total && total < 10**72);

        vm.startPrank(alice);
        uint256[] memory sellOrderIDs = OrderHelper.getSellOrderIDs(dex, marketId, price);
        // for (uint256 i = 0; i < sellOrderIDs.length; i++) {
        //     console.log("nums[%s] = %s", i, sellOrderIDs[i]);
        // }
        dex.placeBuyOrder(marketId, price, quantity, 0, sellOrderIDs, address(0));
        vm.stopPrank();
    }

}
