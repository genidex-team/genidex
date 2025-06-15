// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./GeniDexBase.sol";

abstract contract Balances is GeniDexBase {
    using SafeERC20 for IERC20;
    event Deposit(address indexed sender, address indexed token, uint256 amount);
    event Withdrawal(address indexed recipient, address indexed token, uint256 amount);

    // Ether
    function depositEth()
    external payable nonReentrant whenNotPaused {
        if(msg.value <= 0){
            revert Helper.InvalidValue(msg.value);
        }
        balances[msg.sender][address(0)] += msg.value;
        emit Deposit(msg.sender, address(0), msg.value);
    }

    function withdrawEth(
        uint256 amount
    ) external nonReentrant whenNotPaused
    {
        if(amount <= 0){
            revert Helper.InvalidValue(amount);
        }
        if(amount > balances[msg.sender][address(0)]){
            revert Helper.InsufficientBalance(balances[msg.sender][address(0)], amount);
        }
        balances[msg.sender][address(0)] -= amount;

        emit Withdrawal(msg.sender, address(0), amount);

        bool success = payable(msg.sender).send(amount);
        if(!success){
            revert Helper.TransferFailed({
                from: address(this),
                to: msg.sender,
                amount: amount
            });
        }
    }

    // Token
    function depositToken(
        address tokenAddress,
        uint256 normalizedAmount
    ) external nonReentrant whenNotPaused
    {
        Token storage sToken = tokens[tokenAddress];
        uint8 tokenDecimals = sToken.decimals;
        if (tokenDecimals <= 0) {
            revert Helper.TokenNotListed(tokenAddress);
        }

        uint256 rawAmount = Helper._normalize(normalizedAmount, 18, tokenDecimals);
        if(tokenDecimals<18){
            normalizedAmount = Helper._normalize(rawAmount, tokenDecimals, 18);
        }
        if(normalizedAmount < 1 || rawAmount < 1){
            revert Helper.AmountTooSmall(normalizedAmount, 1);
        }

        IERC20 token = IERC20(tokenAddress);
        uint256 pre = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), rawAmount);
        uint256 received = token.balanceOf(address(this)) - pre;
        // require(received == rawAmount, "transfer mismatch");
        require(received > 0, "no tokens received");
        if(received != rawAmount){
            normalizedAmount = Helper._normalize(received, tokenDecimals, 18);
        }
        balances[msg.sender][tokenAddress] += normalizedAmount;
        emit Deposit(msg.sender, tokenAddress, normalizedAmount);
    }

    function withdrawToken(address tokenAddress, uint256 normalizedAmount)
        external
        nonReentrant
    {

        uint256 userBal = balances[msg.sender][tokenAddress];
        // require(userBal >= normalizedAmount, "insufficient balance");
        if(normalizedAmount > userBal){
            revert Helper.InsufficientBalance(userBal, normalizedAmount);
        }
        Token storage sToken = tokens[tokenAddress];
        uint8 tokenDecimals = sToken.decimals;
        if (tokenDecimals <= 0) {
            revert Helper.TokenNotListed(tokenAddress);
        }
        uint256 rawAmount = Helper._normalize(normalizedAmount, 18, tokenDecimals);
        if(tokenDecimals<18){
            normalizedAmount = Helper._normalize(rawAmount, tokenDecimals, 18);
        }
        require(rawAmount > 0, "Withdraw amount too small");
        require(normalizedAmount != 0, "amount=0");

        balances[msg.sender][tokenAddress] = userBal - normalizedAmount;

        IERC20 token = IERC20(tokenAddress);
        uint256 pre = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, rawAmount);
        uint256 post = token.balanceOf(address(this));
        require(pre - post <= rawAmount, "transfer mismatch");

        emit Withdrawal(msg.sender, tokenAddress, normalizedAmount);
    }

    function getTokenBalance(address tokenAddress) external view returns (uint256){
        return balances[msg.sender][tokenAddress];
    }

    function getEthBalance() external view returns (uint256){
        return balances[msg.sender][address(0)];
    }

}