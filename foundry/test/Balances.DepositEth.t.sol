// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {GeniDex, GeniDexHelper} from "./GeniDexHelper.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
//@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol
// import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DepositEth_Fuzz is Test {
    GeniDex dex;
    address payable alice;
    address payable bob;

    function setUp() public {
        dex = GeniDexHelper.deploy();

        alice = payable(vm.addr(1));
    }

    function testFuzz_DepositEth(uint256 amount) public {
        // amount = bound(amount, 1 wei, 1_000_000 ether);
        vm.assume(amount>0 && amount <= 1_000_000 ether);

        uint256 beforeBalAlice = dex.balances(alice, address(0));
        uint256 beforeDexEth   = address(dex).balance;

        vm.prank(alice);
        vm.deal(alice, amount);
        dex.depositEth{value: amount}();

        // Alice's balance in GeniDex
        assertEq(
            dex.balances(alice, address(0)),
            beforeBalAlice + amount,
            "mapping update incorrect"
        );

        // GeniDex's balance
        assertEq(
            address(dex).balance,
            beforeDexEth + amount,
            "contract ETH balance mismatch"
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                               NEGATIVE CASES                               */
    /* -------------------------------------------------------------------------- */

    function testDepositEth_zeroValueReverts() public {
        vm.expectRevert();
        dex.depositEth{value: 0}();
    }

    function testDepositEth_pausedReverts(uint256 amount) public {
        amount = bound(amount, 1 wei, 1 ether);
        dex.pause();
        vm.expectRevert();
        dex.depositEth{value: amount}();
    }
}
