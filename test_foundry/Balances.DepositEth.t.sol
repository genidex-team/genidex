// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import  "../contracts/GeniDex.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
//@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol
// import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DepositEth_Fuzz is Test {
    GeniDex dex;
    address payable alice;
    address payable bob;

    function setUp() public {
        GeniDex impl = new GeniDex();
        bytes memory initData =
            abi.encodeWithSignature("initialize(address)", address(this));
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        dex = GeniDex(payable(address(proxy)));

        alice = payable(vm.addr(1));
        bob   = payable(vm.addr(2));

        vm.deal(alice, 1_000 ether);
        vm.deal(bob,   1_000 ether);
    }

    function testFuzz_DepositEth(uint256 amount) public {
        amount = bound(amount, 1 wei, 100 ether);

        uint256 beforeBalAlice = dex.balances(alice, address(0));
        uint256 beforeDexEth   = address(dex).balance;

        vm.prank(alice);
        dex.depositEth{value: amount}();

        assertEq(
            dex.balances(alice, address(0)),
            beforeBalAlice + amount,
            "mapping update incorrect"
        );
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
