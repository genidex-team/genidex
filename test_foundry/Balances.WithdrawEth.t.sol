// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/GeniDex.sol";
import "./Functions.sol";

/**
 * @title BalancesWithdrawEthTest (with fuzz‑testing)
 * @dev Foundry test‑suite for the `withdrawEth` function in `Balances.sol`.
 *
 * Behaviour verified:
 *   1. **Fuzz‑tests** ensure (3) and correctness hold for a broad range of deposit/withdraw pairs.
 *   2. Successful withdrawal transfers ETH, updates ledger and emits `Withdrawal`.
 *   3. Withdrawal of `0` reverts with `InvalidValue` (code BL21).
 *   4. Withdrawal greater than balance reverts with `InsufficientBalance` (code BL24).
 *
 */

contract BalancesWithdrawEthTest is Test, Functions {

    GeniDex internal dex;
    address internal alice = address(0xA11CE);

    // Mirror the event signature so that `vm.expectEmit` can be used.
    event Withdrawal(address indexed recipient, address indexed token, uint256 amount);

    function setUp() public {
        dex = _deployGenidex();

        // Seed Alice with 1000 ether for paying gas & deposits
        vm.deal(alice, 1000 ether);
    }

    // ---------------------------------------------------------------------
    // Fuzz tests
    // ---------------------------------------------------------------------

    /**
     * @notice Fuzz successful `withdrawEth` against a wide range of amounts.
     *
     * @param depositAmount  The amount Alice deposits (1 wei – 100 ether).
     * @param withdrawAmount The amount she later withdraws (1 wei – depositAmount).
     */
    function testFuzzWithdrawEth_Succeeds(
        uint96 depositAmount,
        uint96 withdrawAmount
    ) public {
        // Restrict ranges to keep gas & uint96 casting sane
        vm.assume(depositAmount > 0 && depositAmount <= 100 ether);
        vm.assume(withdrawAmount > 0 && withdrawAmount <= depositAmount);

        // ───── Arrange ────────────────────────────────────────────────────
        vm.startPrank(alice);
        dex.depositEth{value: uint256(depositAmount)}();

        uint256 alicePre    = alice.balance;
        uint256 contractPre = address(dex).balance;

        // ───── Act ────────────────────────────────────────────────────────
        dex.withdrawEth(uint256(withdrawAmount));

        // ───── Assert ─────────────────────────────────────────────────────
        assertEq(alice.balance, alicePre + withdrawAmount, "Alice ETH incorrect");
        assertEq(address(dex).balance, contractPre - withdrawAmount, "Contract ETH incorrect");
        assertEq(
            dex.balances(alice, address(0)),
            depositAmount - withdrawAmount,
            "Ledger balance incorrect"
        );

        vm.stopPrank();
    }

    /**
     * @notice Fuzz that withdrawal greater than balance always reverts.
     *
     * @param depositAmount The amount deposited (1 wei – 100 ether).
     * @param delta         A positive offset added so withdraw > balance (1 wei – 100 ether).
     */
    function testFuzzWithdrawEth_RevertsWhenOverdrawn(
        uint96 depositAmount,
        uint96 delta
    ) public {
        vm.assume(depositAmount > 0 && depositAmount <= 100 ether);
        vm.assume(delta > 0 && delta <= 100 ether);

        uint256 withdrawAmount = uint256(depositAmount) + uint256(delta);

        vm.startPrank(alice);
        dex.depositEth{value: uint256(depositAmount)}();

        vm.expectRevert(); // InsufficientBalance("BL24", ..)
        dex.withdrawEth(withdrawAmount);

        vm.stopPrank();
    }

    // ---------------------------------------------------------------------
    // Tests
    // ---------------------------------------------------------------------

    /**
     * @dev Should withdraw ETH successfully, adjust ledger balances and emit `Withdrawal`.
     */
    function testWithdrawEth_TransfersEthAndUpdatesLedger() public {
        vm.startPrank(alice);

        // ───── Arrange ────────────────────────────────────────────────────
        dex.depositEth{value: 1 ether}();

        uint256 alicePre   = alice.balance;
        uint256 contractPre = address(dex).balance;

        // Expect correct event emission
        vm.expectEmit(true, true, true, true);
        emit Withdrawal(alice, address(0), 0.4 ether);

        // ───── Act ────────────────────────────────────────────────────────
        dex.withdrawEth(0.4 ether);

        // ───── Assert ─────────────────────────────────────────────────────
        assertEq(alice.balance, alicePre + 0.4 ether, "ETH not received by Alice");
        assertEq(address(dex).balance, contractPre - 0.4 ether, "ETH not debited from contract");
        assertEq(dex.balances(alice, address(0)), 0.6 ether, "Ledger balance incorrect");

        vm.stopPrank();
    }

    /**
     * @dev Should revert when amount == 0 (InvalidValue).
     */
    function testWithdrawEth_RevertsOnZeroAmount() public {
        vm.startPrank(alice);

        vm.expectRevert(); // InvalidValue("BL21", 0)
        dex.withdrawEth(0);

        vm.stopPrank();
    }

    /**
     * @dev Should revert when caller tries to withdraw more than their balance (InsufficientBalance).
     */
    function testWithdrawEth_RevertsOnInsufficientBalance() public {
        vm.startPrank(alice);

        vm.expectRevert(); // InsufficientBalance("BL24", ..)
        dex.withdrawEth(1 ether);

        vm.stopPrank();
    }
}
