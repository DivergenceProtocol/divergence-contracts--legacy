// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./VirtualToken.sol";
import "./lib/SafeDecimalMath.sol";
import "./algo/Pricing.sol";

contract BondingCurve is VirtualToken {

    using SafeDecimalMath for uint;

    uint maxPrice = 0.9999 * 1e18;
    uint minPrice = 1e18 - maxPrice;

    function spearPrice(uint roundId) public view returns(uint) {
        uint spPrice = cSpear[roundId].divideDecimal(spearBalance[roundId][address(this)]);
        return spPrice;
    }

    function shieldPrice(uint roundId) public view returns(uint) {
        uint shPrice = cShield[roundId].divideDecimal(shieldBalance[roundId][address(this)]);
        return shPrice;
    }

    function buySpear(uint roundId, uint cDeltaAmount) internal {
        uint out = tryBuySpear(roundId, cDeltaAmount);
        uint spearInContract = spearBalance[roundId][address(this)];
        uint shieldInContract = shieldBalance[roundId][address(this)];
        if ((cDeltaAmount + cSpear[roundId]).divideDecimal(spearInContract-out) >= maxPrice) {
            setCSpear(roundId, maxPrice.multiplyDecimal(spearInContract));
            addCollateral(roundId, cDeltaAmount);
            // handle shield
            transferSpear(roundId, address(this), msg.sender, out);
            setCShield(roundId, minPrice.multiplyDecimal(shieldInContract));
        } else {
            addCSpear(roundId, cDeltaAmount);
            transferSpear(roundId, address(this), msg.sender, out);
            setCShield(roundId, (1e18 - spearPrice(roundId)).multiplyDecimal(shieldInContract));
        }
    }

    function tryBuySpear(uint roundId, uint cDeltaAmount) internal view returns(uint out){
        out = Pricing.getVirtualOut(cDeltaAmount, cSpear[roundId], spearBalance[roundId][address(this)]);
    }

    function tryBuyShield(uint roundId, uint cDeltaAmount) internal view returns(uint out) {
        out = Pricing.getVirtualOut(cDeltaAmount, cShield[roundId], shieldBalance[roundId][address(this)]);
    }


    function buyShield(uint roundId, uint cDeltaAmount) internal {
        uint out = tryBuyShield(roundId, cDeltaAmount);
        uint spearInContract = spearBalance[roundId][address(this)];
        uint shieldInContract = shieldBalance[roundId][address(this)];
        if ((cDeltaAmount + cShield[roundId]).divideDecimal(shieldInContract-out) >= maxPrice) {
            setCShield(roundId, maxPrice.multiplyDecimal(shieldInContract));
            addCollateral(roundId, cDeltaAmount);
            // handle shield
            transferShield(roundId, address(this), msg.sender, out);
            setCSpear(roundId, minPrice.multiplyDecimal(spearInContract));
        } else {
            addCShield(roundId, cDeltaAmount);
            transferShield(roundId, address(this), msg.sender, out);
            setCSpear(roundId, (1e18 - shieldPrice(roundId)).multiplyDecimal(shieldInContract));
        }
    }

   

    function sellSpear(uint roundId, uint vDeltaAmount) internal returns(uint out) {
        uint shieldInContract = shieldBalance[roundId][address(this)];
        out = trySellSpear(roundId, vDeltaAmount);
        subCSpear(roundId, out);
        transferSpear(roundId, msg.sender, address(this), vDeltaAmount);
        setCShield(roundId, (1e18 - spearPrice(roundId)).multiplyDecimal(shieldInContract));
    }

    function trySellSpear(uint roundId, uint vDeltaAmount) internal view returns(uint out) {
        uint spearInContract = spearBalance[roundId][address(this)];
        out = Pricing.getCollateralOut(vDeltaAmount, spearInContract, cSpear[roundId]);
    }

     function trySellShield(uint roundId, uint vDeltaAmount) internal view returns(uint out) {
        uint shieldInContract = shieldBalance[roundId][address(this)];
        out = Pricing.getCollateralOut(vDeltaAmount, shieldInContract, cShield[roundId]);
    }

    function sellShield(uint roundId, uint vDeltaAmount) internal returns(uint out) {
        out = trySellShield(roundId, vDeltaAmount);
        uint spearInContract = spearBalance[roundId][address(this)];
        subCShield(roundId, out);
        transferShield(roundId, msg.sender, address(this), vDeltaAmount);
        setCSpear(roundId, (1e18 - shieldPrice(roundId)).multiplyDecimal(spearInContract));
    }

    function _afterBuySpear(uint roundId, uint cDeltaAmount) internal virtual {}
    function _afterSellSpear(uint roundId, uint vDeltaAmount) internal virtual {}
    function _afterBuyShield(uint roundId, uint cDeltaAmount) internal virtual {}
    function _afterSellShield(uint roundId, uint vDeltaAmount) internal virtual {}

}