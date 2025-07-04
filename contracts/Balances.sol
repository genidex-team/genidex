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
        uint256 minTransferAmount = tokens[address(0)].minTransferAmount;
        uint256 rawAmount = msg.value;
        uint256 normAmount = Helper._normalize(rawAmount, 18, 8);
        if(normAmount <= minTransferAmount){
            revert Helper.AmountTooSmall(normAmount, minTransferAmount);
        }
        uint80 userID = generateUserID(msg.sender);
        balances[userID][address(0)] += normAmount;
        emit Deposit(msg.sender, address(0), normAmount);
    }

    function withdrawEth(
        uint256 amount
    ) external nonReentrant whenNotPaused
    {
        uint256 minTransferAmount = tokens[address(0)].minTransferAmount;
        if(amount <= minTransferAmount){
            revert Helper.AmountTooSmall(amount, minTransferAmount);
        }
        uint80 userID = userIDs[msg.sender];
        if(userID<=0){
            revert Helper.UserNotFound(msg.sender);
        }
        if(amount > balances[userID][address(0)]){
            revert Helper.InsufficientBalance(balances[userID][address(0)], amount);
        }
        balances[userID][address(0)] -= amount;

        emit Withdrawal(msg.sender, address(0), amount);

        uint256 rawAmount = Helper._normalize(amount, 8, 18);
        bool success = payable(msg.sender).send(rawAmount);
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

        uint256 rawAmount = Helper._normalize(normalizedAmount, 8, tokenDecimals);
        if(tokenDecimals<8){
            normalizedAmount = Helper._normalize(rawAmount, tokenDecimals, 8);
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
            normalizedAmount = Helper._normalize(received, tokenDecimals, 8);
        }
        uint80 userID = generateUserID(msg.sender);
        balances[userID][tokenAddress] += normalizedAmount;
        emit Deposit(msg.sender, tokenAddress, normalizedAmount);
    }

    function withdrawToken(address tokenAddress, uint256 normalizedAmount)
        external
        nonReentrant
    {
        uint80 userID = userIDs[msg.sender];
        if(userID<=0){
            revert Helper.UserNotFound(msg.sender);
        }
        uint256 userBal = balances[userID][tokenAddress];
        // require(userBal >= normalizedAmount, "insufficient balance");
        if(normalizedAmount > userBal){
            revert Helper.InsufficientBalance(userBal, normalizedAmount);
        }
        Token storage sToken = tokens[tokenAddress];
        uint8 tokenDecimals = sToken.decimals;
        if (tokenDecimals <= 0) {
            revert Helper.TokenNotListed(tokenAddress);
        }
        uint256 rawAmount = Helper._normalize(normalizedAmount, 8, tokenDecimals);
        if(tokenDecimals<8){
            normalizedAmount = Helper._normalize(rawAmount, tokenDecimals, 8);
        }
        require(rawAmount > 0, "Withdraw amount too small");
        require(normalizedAmount != 0, "amount=0");

        balances[userID][tokenAddress] = userBal - normalizedAmount;

        IERC20 token = IERC20(tokenAddress);
        uint256 pre = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, rawAmount);
        uint256 post = token.balanceOf(address(this));
        require(pre - post <= rawAmount, "transfer mismatch");

        emit Withdrawal(msg.sender, tokenAddress, normalizedAmount);
    }

    function getBalance(address account, address tokenOrEtherAddress) external view returns (uint256){
        uint80 userID = userIDs[account];
        return balances[userID][tokenOrEtherAddress];
    }

    function getEthBalance() external view returns (uint256){
        uint80 userID = userIDs[msg.sender];
        return balances[userID][address(0)];
    }

}