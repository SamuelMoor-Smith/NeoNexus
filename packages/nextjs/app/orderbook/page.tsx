"use client";

import { useMemo } from "react";
import { useContractRead } from 'wagmi';
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth/useDeployedContractInfo";

function useFetchOrders() {
    const { data: deployedContractData } = useDeployedContractInfo('OrderBookSwap');

    const { data: dataA4B } = useContractRead({
        address: deployedContractData?.address,
        abi: deployedContractData?.abi,
        functionName: 'getAllOrdersAforB',
    });

    const ordersA4B = useMemo(() => {
        if (!dataA4B) return [];
        return dataA4B.filter(order => !order.orderFilled).map((order, index) => {
            const sellingAmount = Number(order.sellingAmount);
            const buyingAmount = Number(order.buyingAmount);
            return {
                id: index,
                type: 'Green',
                trader: order.trader,
                greenAmount: isNaN(sellingAmount) ? 0 : sellingAmount,
                orangeAmount: isNaN(buyingAmount) ? 0 : buyingAmount,
                isFilled: order.orderFilled
            };
        });
    }, [dataA4B]);

    const { data: dataB4A } = useContractRead({
        address: deployedContractData?.address,
        abi: deployedContractData?.abi,
        functionName: 'getAllOrdersBforA',
    });

    const ordersB4A = useMemo(() => {
        if (!dataB4A) return [];
        return dataB4A.filter(order => !order.orderFilled).map((order, index) => {
            const sellingAmount = Number(order.sellingAmount);
            const buyingAmount = Number(order.buyingAmount);
            return {
                id: index,
                type: 'Orange',
                trader: order.trader,
                greenAmount: isNaN(buyingAmount) ? 0 : buyingAmount,
                orangeAmount: isNaN(sellingAmount) ? 0 : sellingAmount,
                isFilled: order.orderFilled
            };
        });
    }, [dataB4A]);

    return {
        ordersA4B,
        ordersB4A,
        isError: false, // Set proper error handling based on your project requirements
        isLoading: false // Set loading status appropriately
    };
}

const OrderBook = () => {
    const { ordersA4B, ordersB4A, isLoading, isError } = useFetchOrders();

    if (isLoading) return <p>Loading...</p>;
    if (isError) return <p>Error loading orders.</p>;

    return (
      <div className="container mx-auto mt-10">
        <table className="table-auto w-full">
          <thead>
            <tr>
              <th className="px-4 py-2 text-left">Order ID</th>
              <th className="px-4 py-2 text-left">Trader</th>
              <th className="px-4 py-2 text-left">Green Amount</th>
              <th className="px-4 py-2 text-left">Orange Amount</th>
            </tr>
          </thead>
          <tbody>
            {[...ordersA4B, ...ordersB4A].map((order, index) => (
                <tr key={index} className={order.type === 'Green' ? 'bg-green-200' : 'bg-orange-200'}>
                    <td className="border px-4 py-2">{index}</td>
                    <td className="border px-4 py-2">{order.trader}</td>
                    <td className="border px-4 py-2">{order.greenAmount}</td>
                    <td className="border px-4 py-2">{order.orangeAmount}</td>
                </tr>
            ))}
          </tbody>
        </table>
      </div>
    );
};

export default OrderBook;
