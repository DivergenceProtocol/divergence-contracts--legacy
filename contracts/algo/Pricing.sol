// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lib/DMath.sol";
import "../lib/SafeDecimalMath.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

library Pricing {
    
    using SafeMath for uint;
    using SafeDecimalMath for uint;

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

    function getVirtualOut(uint cDeltaAmount, uint cAmount, uint vAmount) internal view returns(uint) {
        console.log("cDeltaAmount %s, cAmount %s, vAmount %s", cDeltaAmount, cAmount, vAmount); 
        if (cAmount.divideDecimal(vAmount) >= 0.9999 * 1e18) {
            return cDeltaAmount;
        }
        uint cLimitAmount = DMath.sqrt(cAmount*vAmount.mul(9999).div(10000));
        uint vLimitAmount = DMath.sqrt(cAmount*vAmount.mul(10000).div(9999));
        if (cDeltaAmount + cAmount > cLimitAmount) {
            return vAmount - vLimitAmount + cDeltaAmount - cLimitAmount + cAmount;
        } else {
            uint numerator = vAmount * cDeltaAmount;
            uint denominator = cAmount + cDeltaAmount;
            return numerator / denominator;
        }
    }

    function getCollateralOut(uint vDeltaAmount, uint vAmount, uint cAmount) internal pure returns(uint) {
        uint numerator = cAmount * vDeltaAmount;
        uint denominator = vAmount + vDeltaAmount;
        return numerator / denominator;
    }

}