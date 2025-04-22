// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Storage.sol";

abstract contract Balances is Storage{

    event Deposit(address indexed sender, address indexed token, uint256 amount);
    event Withdrawal(address indexed recipient, address indexed token, uint256 amount);

    // Ether
    function depositEth()
    external payable nonReentrant whenNotPaused {
        if(msg.value <= 0){
            revert Helper.InvalidValue('BL16', msg.value);
        }
        balances[msg.sender][address(0)] += msg.value;
        emit Deposit(msg.sender, address(0), msg.value);
    }

    function withdrawEth(
        uint256 amount
    ) external nonReentrant whenNotPaused
    {
        if(amount <= 0){
            revert Helper.InvalidValue('BL21', amount);
        }
        if(amount > balances[msg.sender][address(0)]){
            revert Helper.InsufficientBalance('BL24', balances[msg.sender][address(0)], amount);
        }
        balances[msg.sender][address(0)] -= amount;

        bool success = payable(msg.sender).send(amount);
        if( success != true){
            revert Helper.TransferFailed({
                code: 'BL30',
                from: address(this),
                to: msg.sender,
                amount: amount
            });
        }
        emit Withdrawal(msg.sender, address(0), amount);
    }

    // Token
    function depositToken(
        address tokenAddress,
        uint256 amount
    ) external nonReentrant whenNotPaused
    {
        IERC20 token = IERC20(tokenAddress);
        if(token.transferFrom(msg.sender, address(this), amount) != true) {
            revert Helper.TokenTransferFailed({
                code: 'BL39',
                tokenAddress: tokenAddress,
                from: msg.sender,
                to: address(this),
                amount: amount
            });
        }
        balances[msg.sender][tokenAddress] += amount;
        emit Deposit(msg.sender, tokenAddress, amount);
    }

    function withdrawToken(
        address tokenAddress,
        uint256 amount
    ) external nonReentrant whenNotPaused
    {
        if(amount <= 0){
            revert Helper.InvalidValue('BL52', amount);
        }
        if(amount > balances[msg.sender][tokenAddress]){
            revert Helper.InsufficientBalance('BL55', balances[msg.sender][tokenAddress], amount);
        }

        IERC20 token = IERC20(tokenAddress);
        balances[msg.sender][tokenAddress] -= amount;
        if( token.transfer(msg.sender, amount) != true){
            revert Helper.TokenTransferFailed({
                code: 'BL62',
                tokenAddress: tokenAddress,
                from: address(this),
                to: msg.sender,
                amount: amount
            });
        }
        emit Withdrawal(msg.sender, tokenAddress, amount);
    }

    function getTokenBalance(address tokenAddress) external view returns (uint256){
        return balances[msg.sender][tokenAddress];
    }

    function getEthBalance() external view returns (uint256){
        return balances[msg.sender][address(0)];
    }

}