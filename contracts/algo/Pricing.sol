// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lib/DMath.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library Pricing {
    
    using SafeMath for uint;

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint _pre_k) internal pure returns(uint amountOut, bool e, uint pre_k) {
        require(amountIn > 0, 'Battle: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'Battle: INSUFFICIENT_LIQUIDITY');
        if (reserveIn >= reserveOut.mul(99).div(100)) {
            amountOut = amountIn;
            e = true;
            return (amountOut, e, _pre_k);
        }
        // if amountIn > sqrt(reserveIn)
        uint maxAmount = DMath.sqrt(reserveIn*reserveOut.mul(100).div(99));
        pre_k = maxAmount;
        // console.log("maxAmount %s and amountIn %s, reserveIn %s, reserveOut %s", maxAmount, amountIn, reserveIn);
        if (amountIn.add(reserveIn) > maxAmount) {
            uint maxAmountIn = maxAmount.sub(reserveIn);
            uint amountInWithFee = maxAmountIn.mul(1000);
            uint numerator = amountInWithFee.mul(reserveOut);
            uint denominator = reserveIn.mul(1000).add(amountInWithFee);
            amountOut = numerator / denominator;
            amountOut = amountOut.add(amountIn.sub(maxAmountIn));
            e = true;
        } else {
            uint amountInWithFee = amountIn.mul(1000);
            uint numerator = amountInWithFee.mul(reserveOut);
            uint denominator = reserveIn.mul(1000).add(amountInWithFee);
            amountOut = numerator / denominator;
        }
    }

    function getAmountIn() internal view {

    }
}