// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./VirtualToken.sol";
import "./lib/SafeDecimalMath.sol";
import "./algo/Pricing.sol";

contract BondingCurve is VirtualToken {

    using SafeDecimalMath for uint;

    uint public maxPrice;
    uint public minPrice;
    uint public feeRatio;

    // =======VIEW========
    function spearPrice(uint roundId) public view returns(uint) {
        uint spPrice = cSpear[roundId].divideDecimal(spearBalance[roundId][address(this)]);
        if (spPrice >= maxPrice) {
            spPrice = maxPrice;
        }
        if (spPrice <= minPrice) {
            spPrice = minPrice;
        }
        return spPrice;
    }

    function shieldPrice(uint roundId) public view returns(uint) {
        uint shPrice = cShield[roundId].divideDecimal(shieldBalance[roundId][address(this)]);
        if (shPrice >= maxPrice) {
            shPrice = maxPrice;
        }
        if (shPrice <= minPrice) {
            shPrice = minPrice;
        }
        return shPrice;
    }

    function _tryBuy(uint ri, uint cDelta, uint spearOrShield) internal view returns(uint out, uint fee) {
        fee = cDelta.multiplyDecimal(feeRatio);
        uint cDeltaAdjust = cDelta - fee;
        if (spearOrShield == 0) {
            // buy spear
            out = Pricing.getVirtualOut(cDeltaAdjust, cSpear[ri], spearBalance[ri][address(this)]);
            // require(out <= spearBalance[ri][address(this)], "Liquidity Not Enough");
        } else if (spearOrShield == 1) {
            // buy shield
            out = Pricing.getVirtualOut(cDelta, cShield[ri], shieldBalance[ri][address(this)]);
            // require(out <= shieldBalance[ri][address(this)], "Liquidity Not Enough");
        } else {
            revert("must spear or shield");
        }
    }

    function _trySell(uint ri, uint vDelta, uint spearOrShield) internal view returns(uint outAdjust, uint fee) {
        uint out;
        if (spearOrShield == 0) {
            uint spearInContract = spearBalance[ri][address(this)];
            out = Pricing.getCollateralOut(vDelta, spearInContract, cSpear[ri]);
        } else if (spearOrShield == 1) {
            uint shieldInContract = shieldBalance[ri][address(this)];
            out = Pricing.getCollateralOut(vDelta, shieldInContract, cShield[ri]);
        } else {
            revert("must spear or shield");
        }
        fee = out.multiplyDecimal(feeRatio);
        outAdjust = out - fee;
    }

    // =====MUT=====

    function _buy(uint ri, uint cDelta, uint spearOrShield, uint outMin) internal returns(uint out, uint fee){
        (out, fee) = _tryBuy(ri, cDelta, spearOrShield);
        require(out >= outMin, "insufficient out");
        uint spearInContract = spearBalance[ri][address(this)];
        uint shieldInContract = shieldBalance[ri][address(this)];
        if (spearOrShield == 0) {
            // spear
            bool isExcceed = (cDelta + cSpear[ri]).divideDecimal(spearInContract-out) >= maxPrice;
            if (isExcceed) {
                transferSpear(ri, address(this), msg.sender, out);
                // setCSpear(ri, maxPrice.multiplyDecimal(spearInContract-out));
                addCSpear(ri, cDelta);
                // addCollateral(ri, cDelta);
                // handle shield
                setCShield(ri, minPrice.multiplyDecimal(shieldInContract));
            } else {
                addCSpear(ri, cDelta);
                transferSpear(ri, address(this), msg.sender, out);
                setCShield(ri, (1e18 - spearPrice(ri)).multiplyDecimal(shieldInContract));
            }
        } else if (spearOrShield == 1) {
            // shield
            bool isExcceed = (cDelta + cShield[ri]).divideDecimal(shieldInContract-out) >= maxPrice;
            if (isExcceed) {
                // console.log("excceed");            
                transferShield(ri, address(this), msg.sender, out);
                // setCShield(ri, maxPrice.multiplyDecimal(shieldInContract-out));
                // addCollateral(ri, cDelta);

                addCShield(ri, cDelta);
                // handle spear 
                setCSpear(ri, minPrice.multiplyDecimal(spearInContract));
            } else {
                // console.log("not excceed");            
                addCShield(ri, cDelta);
                // console.log("shield in contract 0 %s", shieldInContract);
                transferShield(ri, address(this), msg.sender, out);
                setCSpear(ri, (1e18 - shieldPrice(ri)).multiplyDecimal(spearInContract));
            }
        } else {
            revert("must spear or shield");
        }

    }

    function _sell(uint ri, uint vDelta, uint spearOrShield, uint outMin) internal returns(uint out, uint fee) {
        (out, fee) = _trySell(ri, vDelta, spearOrShield);
        require(out >= outMin, "insufficient out");
        if (spearOrShield == 0) {
            uint shieldInContract = shieldBalance[ri][address(this)];
            subCSpear(ri, out);
            transferSpear(ri, msg.sender, address(this), vDelta);
            setCShield(ri, (1e18 - spearPrice(ri)).multiplyDecimal(shieldInContract));
        } else if (spearOrShield == 1) {
            uint spearInContract = spearBalance[ri][address(this)];
            subCShield(ri, out);
            transferShield(ri, msg.sender, address(this), vDelta);
            setCSpear(ri, (1e18 - shieldPrice(ri)).multiplyDecimal(spearInContract));
        } else {
            revert("must spear or shield");
        }
    }

    function _afterBuySpear(uint roundId, uint cDeltaAmount) internal virtual {}
    function _afterSellSpear(uint roundId, uint vDeltaAmount) internal virtual {}
    function _afterBuyShield(uint roundId, uint cDeltaAmount) internal virtual {}
    function _afterSellShield(uint roundId, uint vDeltaAmount) internal virtual {}

}