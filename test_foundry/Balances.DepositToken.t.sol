// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/GeniDex.sol";
// import "../contracts/test/TestToken.sol";
import "./Functions.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// ────────────────────────────────────────────────────────────────────────────
// Deposit Token test‑suite (fuzzing focus)
// ────────────────────────────────────────────────────────────────────────────

/**
 * @dev Minimal ERC20 implementation with public mint for testing.
 */
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MCK") {}
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

contract BalancesDepositTokenTest is Test, Functions {
    GeniDex internal dex;
    MockERC20 internal token;
    address internal alice = address(0xA11CE);

    event Deposit(address indexed sender, address indexed token, uint256 amount);

    function setUp() public {
        dex = _deployGenidex();

        token = new MockERC20();
        token.mint(alice, 1_000_000 ether);
    }

    // -----------------------------------------------------
    // Fuzz success path
    // -----------------------------------------------------

    /**
     * Fuzz successful `depositToken` behaviour.
     * @param amount 1 wei – 100_000 ether.
     */
    function testFuzzDepositToken_Succeeds(uint96 amount) public {
        vm.assume(amount > 0 && amount <= 100_000 ether);

        vm.prank(alice);
        token.approve(address(dex), amount);

        vm.startPrank(alice);
        uint256 aliceBalPre   = token.balanceOf(alice);
        uint256 contractBalPre = token.balanceOf(address(dex));

        // Expect Deposit event
        vm.expectEmit(true, true, true, true);
        emit Deposit(alice, address(token), amount);
        dex.depositToken(address(token), amount);
        // Assertions
        assertEq(token.balanceOf(alice), aliceBalPre - amount, "Token not debited from Alice");
        assertEq(token.balanceOf(address(dex)), contractBalPre + amount, "Token not credited to contract");
        assertEq(dex.balances(alice, address(token)), amount, "Ledger balance incorrect");
        vm.stopPrank();
    }

    // -----------------------------------------------------
    // Fuzz revert scenarios
    // -----------------------------------------------------

    /// Deposit zero should revert.
    function testDepositToken_RevertsOnZeroAmount() public {
        vm.prank(alice);
        token.approve(address(dex), 0);

        vm.startPrank(alice);
        vm.expectRevert(); // InvalidValue("BL22", 0) – assuming similar code
        dex.depositToken(address(token), 0);
        vm.stopPrank();
    }

    /// Deposit larger than allowance must revert.
    function testFuzzDepositToken_RevertsOnAllowance(uint96 allowance, uint96 delta) public {
        vm.assume(allowance > 0 && allowance <= 100_000 ether);
        vm.assume(delta > 0 && delta <= 100_000 ether);

        uint256 amount = uint256(allowance) + uint256(delta); // > allowance

        vm.prank(alice);
        token.approve(address(dex), allowance);

        vm.startPrank(alice);
        vm.expectRevert();
        dex.depositToken(address(token), amount);
        vm.stopPrank();
    }
}