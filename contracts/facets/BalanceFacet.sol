// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardTransientUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "../Storage.sol";
import "../Helper.sol";
import "../libraries/LibPausable.sol";

contract BalanceFacet is ReentrancyGuardTransientUpgradeable, LibPausable {
    using SafeERC20 for IERC20;
    event Deposit(address indexed sender, address indexed token, uint256 amount);
    event Withdrawal(address indexed recipient, address indexed token, uint256 amount);
    event DebugTransfer(address indexed to, uint256 amount);

    // Ether
    function depositEth()
    external payable nonReentrant whenNotPaused {
        Storage.TokenData storage t = Storage.token();
        Storage.UserData storage u = Storage.user();
        uint256 minTransferAmount = t.tokens[address(0)].minTransferAmount;
        uint256 rawAmount = msg.value;
        uint256 normAmount = Helper._normalize(rawAmount, 18, 8);
        if(normAmount < minTransferAmount){
            revert Helper.AmountTooSmall(normAmount, minTransferAmount);
        }
        uint80 userID = _generateUserID(msg.sender);
        u.balances[userID][address(0)] += normAmount;
        emit Deposit(msg.sender, address(0), normAmount);
    }

    function msgSender() internal view returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
    }

    function withdrawEth(
        uint256 amount
    ) external nonReentrant whenNotPaused
    {
        Storage.TokenData storage t = Storage.token();
        Storage.UserData storage u = Storage.user();
        uint256 minTransferAmount = t.tokens[address(0)].minTransferAmount;
        if(amount < minTransferAmount){
            revert Helper.AmountTooSmall(amount, minTransferAmount);
        }
        uint80 userID = u.userIDs[msg.sender];
        if(userID<=0){
            revert Helper.UserNotFound(msg.sender);
        }
        if(amount > u.balances[userID][address(0)]){
            revert Helper.InsufficientBalance(u.balances[userID][address(0)], amount);
        }

        

        u.balances[userID][address(0)] -= amount;

        address recipient = msgSender();
        emit Withdrawal(recipient, address(0), amount);

        uint256 rawAmount = Helper._normalize(amount, 8, 18);
        if( address(this).balance < rawAmount ){
            revert ('balance < rawAmount');
        }
        // bool success = payable(msg.sender).send(rawAmount);
        (bool success, ) = payable(msg.sender).call{value: rawAmount}("");
        // emit DebugTransfer(recipient, rawAmount);
        // payable(recipient).transfer(rawAmount);
        if(!success){
            revert Helper.TransferFailed({
                from: address(this),
                to: msg.sender,
                amount: rawAmount
            });
        }
    }

    // Token
    function depositToken(
        address tokenAddress,
        uint256 normalizedAmount
    ) external nonReentrant whenNotPaused
    {
        Storage.TokenData storage t = Storage.token();
        Storage.UserData storage u = Storage.user();
        Storage.Token storage sToken = t.tokens[tokenAddress];
        uint8 tokenDecimals = sToken.decimals;
        if (tokenDecimals <= 0) {
            revert Helper.TokenNotListed(tokenAddress);
        }

        uint256 rawAmount = Helper._normalize(normalizedAmount, 8, tokenDecimals);
        if(tokenDecimals<8){
            normalizedAmount = Helper._normalize(rawAmount, tokenDecimals, 8);
        }
        if(rawAmount < 1){
            revert Helper.AmountTooSmall(normalizedAmount, 1);
        }
        uint80 minTransferAmount = t.tokens[tokenAddress].minTransferAmount;
        if(normalizedAmount < minTransferAmount){
            revert Helper.AmountTooSmall(normalizedAmount, minTransferAmount);
        }

        IERC20 token = IERC20(tokenAddress);
        uint256 pre = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), rawAmount);
        uint256 received = token.balanceOf(address(this)) - pre;
        if (received == 0) {
            revert Helper.NoTokensReceived();
        }
        if(received != rawAmount){
            normalizedAmount = Helper._normalize(received, tokenDecimals, 8);
        }
        uint80 userID = _generateUserID(msg.sender);
        u.balances[userID][tokenAddress] += normalizedAmount;
        emit Deposit(msg.sender, tokenAddress, normalizedAmount);
    }

    function withdrawToken(address tokenAddress, uint256 normalizedAmount)
        external
        nonReentrant
    {
        Storage.TokenData storage t = Storage.token();
        Storage.UserData storage u = Storage.user();
        uint80 userID = u.userIDs[msg.sender];
        if(userID<=0){
            revert Helper.UserNotFound(msg.sender);
        }
        uint256 userBal = u.balances[userID][tokenAddress];
        if(normalizedAmount > userBal){
            revert Helper.InsufficientBalance(userBal, normalizedAmount);
        }
        Storage.Token storage sToken = t.tokens[tokenAddress];
        uint8 tokenDecimals = sToken.decimals;
        if (tokenDecimals <= 0) {
            revert Helper.TokenNotListed(tokenAddress);
        }
        uint256 rawAmount = Helper._normalize(normalizedAmount, 8, tokenDecimals);
        if(tokenDecimals<8){
            normalizedAmount = Helper._normalize(rawAmount, tokenDecimals, 8);
        }

        if(rawAmount < 1){
            revert Helper.AmountTooSmall(normalizedAmount, 1);
        }
        uint80 minTransferAmount = t.tokens[tokenAddress].minTransferAmount;
        if(normalizedAmount < minTransferAmount){
            revert Helper.AmountTooSmall(normalizedAmount, minTransferAmount);
        }

        u.balances[userID][tokenAddress] = userBal - normalizedAmount;

        IERC20 token = IERC20(tokenAddress);
        uint256 pre = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, rawAmount);
        uint256 post = token.balanceOf(address(this));
        if (pre - post > rawAmount) {
            revert Helper.TransferMismatch(pre - post, rawAmount);
        }

        emit Withdrawal(msg.sender, tokenAddress, normalizedAmount);
    }

    function _generateUserID(address userAddress) internal returns(uint80){
        Storage.UserData storage u = Storage.user();
        uint80 userID = u.userIDs[userAddress];
        if(userID>0){
            return userID;
        }else{
            userID = ++u.userCounter;
            u.userAddresses[userID] = userAddress;
            u.userIDs[userAddress] = userID;
            return userID;
        }
    }

}