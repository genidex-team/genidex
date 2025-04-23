// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Helper {

    // Helper function to find the minimum of two values
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        unchecked {
            c = a + b;
            require(c >= a, 'add: overflow');
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            require(a>=b, 'sub: overflow');
            return a - b;
        }
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return 0;
            uint256 c = a * b;
            require (c / a == b, 'mul: overflow');
            return c;
        }
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            require(b != 0, 'div: division by zero');
            return a / b;
        }
    }

    function addAssembly(uint256 a, uint256 b) internal pure returns (uint256 c){
        // c = a + b;
        assembly {
            c := add(a, b)
            if lt(c, a) {
                // mstore(0x00, message)
                revert(0x00, 0x20)
            }
            mstore(0x00, c)
            // return(0x00, 0x32)
        }
    }

    error InsufficientBalance(string code, uint256 available, uint256 required);
    error TotalTooSmall(string code, uint256 total, uint256 minimumRequired);
    error Unauthorized(string code, address caller, address owner);
    error InvalidValue(string code, uint256 providedValue);
    error OrderAlreadyCanceled(string code, uint orderIndex);
    error TransferFailed(string code, address from, address to, uint amount);
    error TokenTransferFailed(string code, address tokenAddress, address from, address to, uint amount);
    error ReferralRootNotSet(string code);
    error InvalidProof(string code);
    error InvalidMarketId(string code, uint256 marketId, uint256 marketCounter);

}