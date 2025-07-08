// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

library Helper {

    error MarketAlreadyExists(address baseToken, address quoteToken);
    error InsufficientBalance(uint256 available, uint256 required);
    error TotalTooSmall(uint256 total, uint256 minimumRequired);
    error AmountTooSmall(uint256 amount, uint256 minAmount);
    error Unauthorized(uint80 caller, uint80 owner);
    error InvalidValue(uint256 providedValue);
    error OrderAlreadyCanceled(uint orderIndex);
    error TransferFailed(address from, address to, uint amount);
    error TokenTransferFailed(
        string code,
        address tokenAddress,
        address from,
        address to,
        uint amount
    );
    error ReferralRootNotSet();
    error InvalidProof();
    error InvalidMarketId(uint256 marketId, uint256 marketCounter);
    error TokenNotListed(address token);
    error UserNotFound(address user);
    error InvalidTokenAddress();
    error TokenAlreadyListed(address token);
    error SymbolFetchFailed();
    error DecimalsFetchFailed();
    error ManualSymbolRequired();
    error ManualDecimalsRequired();
    error NoTokensReceived();
    error TransferMismatch(uint256 actual, uint256 expected);
    error OnlyRewarderAllowed(address caller);
    error InvalidAddress();
    error InsufficientPoints(uint256 available, uint256 required);
    error ReferrerAlreadySet(address user);
    error SelfReferralNotAllowed(address user);
    error DecimalsExceedLimit(uint8 decimals);
    error NormalizationOverflow(uint256 amount, uint256 factor);

    error AddressAlreadyLinked();


    function _min(uint80 a, uint80 b) internal pure returns (uint80) {
        return a < b ? a : b;
    }

    function _normalize(
        uint256 amount,
        uint8 decimalsFrom,
        uint8 decimalsTo
    ) internal pure returns (uint256 normalized) {
        if (decimalsFrom > 36) {
            revert DecimalsExceedLimit(decimalsFrom);
        }
        if (decimalsTo > 36) {
            revert DecimalsExceedLimit(decimalsTo);
        }

        if (decimalsFrom == decimalsTo) {
            return amount;
        }
        else if (decimalsFrom < decimalsTo) {
            // Upscale: e.g. 6  -> 18  (multiply)
            uint256 factor = 10 ** (decimalsTo - decimalsFrom);
            unchecked {
                normalized = amount * factor;
                // overflow-safety: reverse-check (cheaper than SafeMath)
                if (normalized / factor != amount) {
                    revert NormalizationOverflow(amount, factor);
                }
            }
            return normalized;
        }else{
            // Downscale: e.g. 18 -> 6  (divide)
            uint256 divisor = 10 ** (decimalsFrom - decimalsTo);
            return amount / divisor;
        }
    }
}
