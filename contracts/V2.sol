// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract PreFundedOrderBook {
    using ECDSA for bytes32;

    bytes32 public DOMAIN_SEPARATOR;
    IERC20 public token;

    mapping(address => uint256) public balances;
    mapping(bytes32 => uint128) public filledQuantities;

    struct Order {
        address trader;
        uint128 price;
        uint128 quantity;
        uint256 nonce;
    }

    event OrderMatched(
        bytes32 indexed makerHash,
        bytes32 indexed takerHash,
        address maker,
        address taker,
        uint128 price,
        uint128 quantity
    );

    constructor(IERC20 _token, string memory name, string memory version) {
        token = _token;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                address(this)
            )
        );
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        token.transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        token.transfer(msg.sender, amount);
    }

    function hashOrder(Order memory order) public pure returns (bytes32) {
        return keccak256(abi.encode(
            keccak256("Order(address trader,uint128 price,uint128 quantity,uint256 nonce)"),
            order.trader,
            order.price,
            order.quantity,
            order.nonce
        ));
    }

    function verifySignature(Order memory order, bytes memory signature) public view returns (bool) {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hashOrder(order)
        ));
        return digest.recover(signature) == order.trader;
    }

    struct MakerOrderWithSig {
        Order order;
        bytes signature;
    }

    function matchOrders(
        Order memory takerOrder,
        bytes memory takerSignature,
        MakerOrderWithSig[] memory makerOrders
    ) external {
        require(verifySignature(takerOrder, takerSignature), "Invalid taker signature");
        bytes32 takerHash = hashOrder(takerOrder);

        uint128 remainingTakerQty = takerOrder.quantity - filledQuantities[takerHash];
        require(remainingTakerQty > 0, "Taker order fully filled");

        for (uint i = 0; i < makerOrders.length && remainingTakerQty > 0; i++) {
            MakerOrderWithSig memory maker = makerOrders[i];
            bytes32 makerHash = hashOrder(maker.order);

            require(verifySignature(maker.order, maker.signature), "Invalid maker signature");

            uint128 remainingMakerQty = maker.order.quantity - filledQuantities[makerHash];
            if (remainingMakerQty == 0) continue;

            require(takerOrder.price >= maker.order.price, "Price mismatch");

            uint128 matchQty = remainingTakerQty <= remainingMakerQty
                ? remainingTakerQty
                : remainingMakerQty;

            uint256 tradeAmount = uint256(matchQty) * maker.order.price;

            // Check pre-funded balances
            require(balances[takerOrder.trader] >= tradeAmount, "Taker insufficient balance");
            require(balances[maker.order.trader] >= matchQty, "Maker insufficient balance");

            // Update filled quantities
            filledQuantities[makerHash] += matchQty;
            filledQuantities[takerHash] += matchQty;

            // Update balances
            balances[takerOrder.trader] -= tradeAmount;
            balances[maker.order.trader] += tradeAmount;

            balances[maker.order.trader] -= matchQty;
            balances[takerOrder.trader] += matchQty;

            remainingTakerQty -= matchQty;

            emit OrderMatched(
                makerHash,
                takerHash,
                maker.order.trader,
                takerOrder.trader,
                maker.order.price,
                matchQty
            );
        }
    }

    function filledQuantity(Order memory order) external view returns (uint128) {
        return filledQuantities[hashOrder(order)];
    }
}
