// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./VirtualToken.sol";
import "./lib/SafeDecimalMath.sol";
import "./algo/Pricing.sol";

contract BondingCurve is VirtualToken {
    using SafeDecimalMath for uint256;

    uint256 public maxPrice;
    uint256 public minPrice;
    uint256 public feeRatio;

    // VPrice => virtual token price => spear/shield price
    event VPriceUpdated(uint256 ri, uint256 _spearPrice, uint256 _shieldPrice);
    event CollateralUpdated(uint256 ri, uint256 cSpearAmount, uint256 cShieldAmount, uint256 cSurplusAmount);

    // =======VIEW========
    function spearPrice(uint256 roundId) public view returns (uint256) {
        uint256 spPrice = cSpear[roundId].divideDecimal(spearBalance[roundId][address(this)]);
        if (spPrice >= maxPrice) {
            spPrice = maxPrice;
        }
        if (spPrice <= minPrice) {
            spPrice = minPrice;
        }
        return spPrice;
    }

    function shieldPrice(uint256 roundId) public view returns (uint256) {
        uint256 shPrice = cShield[roundId].divideDecimal(shieldBalance[roundId][address(this)]);
        if (shPrice >= maxPrice) {
            shPrice = maxPrice;
        }
        if (shPrice <= minPrice) {
            shPrice = minPrice;
        }
        return shPrice;
    }

    function _tryBuy(
        uint256 ri,
        uint256 cDelta,
        uint256 spearOrShield
    ) internal view returns (uint256 out, uint256 fee) {
        fee = cDelta.multiplyDecimal(feeRatio);
        uint256 cDeltaAdjust = cDelta - fee;
        if (spearOrShield == 0) {
            // buy spear
            out = Pricing.getVirtualOut(cDeltaAdjust, cSpear[ri], spearBalance[ri][address(this)]);
        } else if (spearOrShield == 1) {
            // buy shield
            out = Pricing.getVirtualOut(cDeltaAdjust, cShield[ri], shieldBalance[ri][address(this)]);
        } else {
            revert("must spear or shield");
        }
    }

    function _trySell(
        uint256 ri,
        uint256 vDelta,
        uint256 spearOrShield
    ) internal view returns (uint256 outAdjust, uint256 fee) {
        uint256 out;
        if (spearOrShield == 0) {
            uint256 spearInContract = spearBalance[ri][address(this)];
            out = Pricing.getCollateralOut(vDelta, spearInContract, cSpear[ri]);
        } else if (spearOrShield == 1) {
            uint256 shieldInContract = shieldBalance[ri][address(this)];
            out = Pricing.getCollateralOut(vDelta, shieldInContract, cShield[ri]);
        } else {
            revert("must spear or shield");
        }
        fee = out.multiplyDecimal(feeRatio);
        outAdjust = out - fee;
    }

    // =====MUT=====

    function _buy(
        uint256 ri,
        uint256 cDelta,
        uint256 spearOrShield,
        uint256 outMin
    ) internal returns (uint256 out, uint256 fee) {
        (out, fee) = _tryBuy(ri, cDelta, spearOrShield);
        require(out >= outMin, "insufficient out");
        uint256 spearInContract = spearBalance[ri][address(this)];
        uint256 shieldInContract = shieldBalance[ri][address(this)];
        if (spearOrShield == 0) {
            // spear
            bool isExcceed = (cDelta + cSpear[ri]).divideDecimal(spearInContract - out) >= maxPrice;
            if (isExcceed) {
                transferSpear(ri, address(this), msg.sender, out);
                addCSpear(ri, cDelta);
                setCShield(ri, minPrice.multiplyDecimal(shieldInContract));
            } else {
                addCSpear(ri, cDelta);
                transferSpear(ri, address(this), msg.sender, out);
                setCShield(ri, (1e18 - spearPrice(ri)).multiplyDecimal(shieldInContract));
            }
        } else if (spearOrShield == 1) {
            // shield
            bool isExcceed = (cDelta + cShield[ri]).divideDecimal(shieldInContract - out) >= maxPrice;
            if (isExcceed) {
                transferShield(ri, address(this), msg.sender, out);
                addCShield(ri, cDelta);
                setCSpear(ri, minPrice.multiplyDecimal(spearInContract));
            } else {
                addCShield(ri, cDelta);
                transferShield(ri, address(this), msg.sender, out);
                setCSpear(ri, (1e18 - shieldPrice(ri)).multiplyDecimal(spearInContract));
            }
        } else {
            revert("must spear or shield");
        }
        emit CollateralUpdated(ri, cSpear[ri], cShield[ri], cSurplus(ri));
        emit VPriceUpdated(ri, spearPrice(ri), shieldPrice(ri));
    }

    function _sell(
        uint256 ri,
        uint256 vDelta,
        uint256 spearOrShield,
        uint256 outMin
    ) internal returns (uint256 out, uint256 fee) {
        (out, fee) = _trySell(ri, vDelta, spearOrShield);
        require(out >= outMin, "insufficient out");
        if (spearOrShield == 0) {
            uint256 shieldInContract = shieldBalance[ri][address(this)];
            subCSpear(ri, out);
            transferSpear(ri, msg.sender, address(this), vDelta);
            setCShield(ri, (1e18 - spearPrice(ri)).multiplyDecimal(shieldInContract));
        } else if (spearOrShield == 1) {
            uint256 spearInContract = spearBalance[ri][address(this)];
            subCShield(ri, out);
            transferShield(ri, msg.sender, address(this), vDelta);
            setCSpear(ri, (1e18 - shieldPrice(ri)).multiplyDecimal(spearInContract));
        } else {
            revert("must spear or shield");
        }
        emit CollateralUpdated(ri, cSpear[ri], cShield[ri], cSurplus(ri));
        emit VPriceUpdated(ri, spearPrice(ri), shieldPrice(ri));
    }

    function _afterBuySpear(uint256 roundId, uint256 cDeltaAmount) internal virtual {}

    function _afterSellSpear(uint256 roundId, uint256 vDeltaAmount) internal virtual {}

    function _afterBuyShield(uint256 roundId, uint256 cDeltaAmount) internal virtual {}

    function _afterSellShield(uint256 roundId, uint256 vDeltaAmount) internal virtual {}
}
