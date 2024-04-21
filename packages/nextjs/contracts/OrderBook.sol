// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OrderBookSwap is ReentrancyGuard {
    address public tokenA;
    address public tokenB;

    struct OrderAforB {
        uint id;
        address trader;
        uint sellingAmount; // amount of tokenA being sold
        uint buyingAmount; // amount of tokenB being bought
        bool orderFilled;
    }

    struct OrderBforA {
        uint id;
        address trader;
        uint sellingAmount; // amount of tokenB being sold
        uint buyingAmount; // amount of tokenA being bought
        bool orderFilled;
    }

    OrderAforB[] public ordersAforB;
    OrderBforA[] public ordersBforA;
    uint public nextOrderId = 1000;  // Counter for unique order IDs

    event OrderPlaced(uint indexed orderId, bool isAforB, uint sellingAmount, uint buyingAmount);
    event OrderMatched(uint indexed orderIdAforB, uint indexed orderIdBforA);
    event OrderCancelled(uint indexed orderId, bool isAforB);

    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function getAllOrdersAforB() public view returns (OrderAforB[] memory) {
        return ordersAforB;
    }

    function getAllOrdersBforA() public view returns (OrderBforA[] memory) {
        return ordersBforA;
    }

    // Users can place orders for trading tokenA for tokenB
    function placeOrderAforB(uint sellingAmount, uint buyingAmount) external nonReentrant {
        require(IERC20(tokenA).transferFrom(msg.sender, address(this), sellingAmount), "Transfer failed");
        uint orderIndex = ordersAforB.length;
        ordersAforB.push(OrderAforB({
            id: nextOrderId++,
            trader: msg.sender,
            sellingAmount: sellingAmount,
            buyingAmount: buyingAmount,
            orderFilled: false
        }));

        emit OrderPlaced(orderIndex, true, sellingAmount, buyingAmount);
        tryMatchAforB(orderIndex);
    }

    // Users can place orders for trading tokenB for tokenA
    function placeOrderBforA(uint sellingAmount, uint buyingAmount) external nonReentrant {
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), sellingAmount), "Transfer failed");
        uint orderIndex = ordersBforA.length;
        ordersBforA.push(OrderBforA({
            id: nextOrderId++,
            trader: msg.sender,
            sellingAmount: sellingAmount,
            buyingAmount: buyingAmount,
            orderFilled: false
        }));

        emit OrderPlaced(orderIndex, false, sellingAmount, buyingAmount);
        tryMatchBforA(orderIndex);
    }

    // Attempt to match a new OrderAforB with existing OrderBforA
    function tryMatchAforB(uint orderIndex) private {
        for (uint i = 0; i < ordersBforA.length; i++) {
            if (!ordersBforA[i].orderFilled &&
                ordersAforB[orderIndex].buyingAmount == ordersBforA[i].sellingAmount &&
                ordersBforA[i].buyingAmount == ordersAforB[orderIndex].sellingAmount) {
                executeTradeAforB(orderIndex, i);
                break;
            }
        }
    }

    // Attempt to match a new OrderBforA with existing OrderAforB
    function tryMatchBforA(uint orderIndex) private {
        for (uint i = 0; i < ordersAforB.length; i++) {
            if (!ordersAforB[i].orderFilled &&
                ordersBforA[orderIndex].buyingAmount == ordersAforB[i].sellingAmount &&
                ordersAforB[i].buyingAmount == ordersBforA[orderIndex].sellingAmount) {
                executeTradeAforB(i, orderIndex);
                break;
            }
        }
    }

    // Execute a trade between an OrderAforB and an OrderBforA
    function executeTradeAforB(uint orderIndexAforB, uint orderIndexBforA) private {
        OrderAforB storage orderA = ordersAforB[orderIndexAforB];
        OrderBforA storage orderB = ordersBforA[orderIndexBforA];

        IERC20(tokenB).transfer(orderA.trader, orderB.sellingAmount);
        IERC20(tokenA).transfer(orderB.trader, orderA.sellingAmount);

        orderA.orderFilled = true;
        orderB.orderFilled = true;
    }
}