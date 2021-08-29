// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../lib/DMath.sol';
import '../lib/SafeDecimalMath.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

library Pricing {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    function getVirtualOut(
        uint256 cDeltaAmount,
        uint256 cAmount,
        uint256 vAmount
    ) internal pure returns (uint256) {
        // if (cAmount.divideDecimal(vAmount) >= 0.9999 * 1e18) {
        if (cAmount.divideDecimal(vAmount) >= 0.99 * 1e18) {
            return cDeltaAmount;
        }
        // uint cLimitAmount = DMath.sqrt(cAmount*vAmount.mul(9999).div(10000));
        // uint vLimitAmount = DMath.sqrt(cAmount*vAmount.mul(10000).div(9999));
        uint256 cLimitAmount = DMath.sqrt(cAmount * vAmount.mul(99).div(100));
        uint256 vLimitAmount = DMath.sqrt(cAmount * vAmount.mul(100).div(99));
        if (cDeltaAmount + cAmount > cLimitAmount) {
            // console.log("%s %s %s ", vAmount/1e18, vLimitAmount/1e18, cDeltaAmount/1e18);
            // console.log("%s %s", cLimitAmount/1e18, cAmount/1e18);
            uint256 result = vAmount -
                vLimitAmount +
                (cDeltaAmount - (cLimitAmount - cAmount));
            return result;
        } else {
            uint256 numerator = vAmount * cDeltaAmount;
            uint256 denominator = cAmount + cDeltaAmount;
            return numerator / denominator;
        }
    }

    function getCollateralOut(
        uint256 vDeltaAmount,
        uint256 vAmount,
        uint256 cAmount
    ) internal pure returns (uint256) {
        if (cAmount.divideDecimal(vAmount) > 0.99e18) {
            uint256 maxAmountBy1 = ((cAmount - (vAmount * 99) / 100) * 100) /
                199;
            if (vDeltaAmount <= maxAmountBy1) {
                return vDeltaAmount;
            } else {
                uint256 numerator = (cAmount - maxAmountBy1) *
                    (vDeltaAmount - maxAmountBy1);
                uint256 denominator = (vAmount + maxAmountBy1) *
                    (vDeltaAmount - maxAmountBy1);
                return numerator / denominator + maxAmountBy1;
            }
        } else {
            uint256 numerator = cAmount * vDeltaAmount;
            uint256 denominator = vAmount + vDeltaAmount;
            return numerator / denominator;
        }
    }
}
