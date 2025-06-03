// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
// import "../contracts/GeniDex.sol";
// import "../contracts/test/TestToken.sol";
import {GeniDex, GeniDexHelper} from "../src/GeniDexHelper.sol";
import "../contracts/test/TestToken.sol";
import "../contracts/Helper.sol";


contract BalancesDepositTokenTest is Test {
    GeniDex internal dex;
    TestToken internal quoteToken;
    TestToken internal baseToken;
    address internal alice = address(0xA11CE);

    event Deposit(address indexed sender, address indexed token, uint256 amount);

    function setUp() public {
        dex = GeniDexHelper.deploy();
        quoteToken =  new TestToken('USDT', 'USDT', 1_000_000_000*10**6, 6);
        dex.updateTokenIsUSD(address(quoteToken), true);
        baseToken =   new TestToken('OP', 'OP', 1_000_000_000*10**18, 18);
        dex.addMarket(address(baseToken), address(quoteToken), 10*10**6);
    }

    // -----------------------------------------------------
    // Fuzz success path
    // -----------------------------------------------------

    /**
     * Fuzz successful `depositToken` behaviour.
     * @param normalizedAmount 1 wei – 100_000 ether.
     */
    function testFuzzDepositToken_Succeeds(uint256 normalizedAmount) public {
        vm.assume(normalizedAmount > 0 && normalizedAmount <= 100_000 ether);
        uint256 rawAmount = Helper._normalize(normalizedAmount, 18, quoteToken.decimals());
        vm.assume(rawAmount > 0);

        vm.startPrank(alice);
        quoteToken.mint(alice, rawAmount);
        quoteToken.approve(address(dex), rawAmount);
        uint256 aliceBalPre   = quoteToken.balanceOf(alice);
        uint256 contractBalPre = quoteToken.balanceOf(address(dex));

        console.log('normalizedAmount', normalizedAmount);
        console.log('rawAmount', rawAmount);
        console.log('aliceBalPre', aliceBalPre);
        // Expect Deposit event
        vm.expectEmit(true, true, true, true);
        emit Deposit(alice, address(quoteToken), normalizedAmount);
        dex.depositToken(address(quoteToken), normalizedAmount);
        // Assertions
        console.log('quoteToken.balanceOf(alice)', quoteToken.balanceOf(alice));
        assertEq(quoteToken.balanceOf(alice), aliceBalPre - rawAmount, "Token not debited from Alice");
        assertEq(quoteToken.balanceOf(address(dex)), contractBalPre + rawAmount, "Token not credited to contract");
        assertEq(dex.balances(alice, address(quoteToken)), normalizedAmount, "Ledger balance incorrect");
        vm.stopPrank();
    }

    // -----------------------------------------------------
    // Fuzz revert scenarios
    // -----------------------------------------------------

    /// Deposit zero should revert.
    function testDepositToken_RevertsOnZeroAmount() public {
        vm.prank(alice);
        quoteToken.approve(address(dex), 0);

        vm.startPrank(alice);
        vm.expectRevert(); // InvalidValue("BL22", 0) – assuming similar code
        dex.depositToken(address(quoteToken), 0);
        vm.stopPrank();
    }

    /// Deposit larger than allowance must revert.
    function testFuzzDepositToken_RevertsOnAllowance(uint96 allowance, uint96 delta) public {
        vm.assume(allowance > 0 && allowance <= 1000 ether);
        vm.assume(delta > 0 && delta <= 100 ether);

        uint256 amount = uint256(allowance) + uint256(delta); // > allowance

        vm.startPrank(alice);
        quoteToken.approve(address(dex), allowance);
        vm.expectRevert();
        dex.depositToken(address(quoteToken), amount);
        vm.stopPrank();
    }
}