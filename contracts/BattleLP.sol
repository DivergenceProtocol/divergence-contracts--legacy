// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BondingCurve.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./lib/SafeDecimalMath.sol";
import "./structs/RoundResult.sol";

contract BattleLP is BondingCurve, ERC20Upgradeable {
    using SafeDecimalMath for uint256;

    mapping(uint256 => uint256) public startPrice;
    mapping(uint256 => uint256) public endPrice;

    mapping(uint256 => uint256) public startTS;
    mapping(uint256 => uint256) public endTS;

    mapping(uint256 => uint256) public strikePrice;
    mapping(uint256 => uint256) public strikePriceOver;
    mapping(uint256 => uint256) public strikePriceUnder;

    mapping(uint256 => RoundResult) public roundResult;

    mapping(address => uint256) public lockTS;

    function _tryAddLiquidity(uint256 ri, uint256 cDeltaAmount)
        internal
        view
        returns (
            uint256 cDeltaSpear,
            uint256 cDeltaShield,
            uint256 deltaSpear,
            uint256 deltaShield,
            uint256 lpDelta
        )
    {
        uint256 cVirtual = cSpear[ri] + cShield[ri];
        cDeltaSpear = cSpear[ri].multiplyDecimal(cDeltaAmount).divideDecimal(cVirtual);
        cDeltaShield = cShield[ri].multiplyDecimal(cDeltaAmount).divideDecimal(cVirtual);
        deltaSpear = spearBalance[ri][address(this)].multiplyDecimal(cDeltaAmount).divideDecimal(cVirtual);
        deltaShield = shieldBalance[ri][address(this)].multiplyDecimal(cDeltaAmount).divideDecimal(cVirtual);
        if (totalSupply() == 0) {
            lpDelta = cDeltaAmount;
        } else {
            lpDelta = cDeltaAmount.multiplyDecimal(totalSupply()).divideDecimal(collateral[ri]);
        }
    }

    function _addLiquidity(uint256 ri, uint256 cDeltaAmount) internal returns (uint256 lpDelta) {
        (uint256 cDeltaSpear, uint256 cDeltaShield, uint256 deltaSpear, uint256 deltaShield, uint256 _lpDelta) = _tryAddLiquidity(ri, cDeltaAmount);
        addCSpear(ri, cDeltaSpear);
        addCShield(ri, cDeltaShield);
        mintSpear(ri, address(this), deltaSpear);
        mintShield(ri, address(this), deltaShield);
        // mint lp
        lpDelta = _lpDelta;
        _mint(msg.sender, lpDelta);

        emit CollateralUpdated(ri, cSpear[ri], cShield[ri], cSurplus(ri));
    }

    function _getCDelta(uint256 ri, uint256 lpDeltaAmount) internal view returns (uint256 cDelta) {
        uint256 spSold = spearSold(ri);
        uint256 shSold = shieldSold(ri);

        uint256 maxSold = spSold > shSold ? spSold : shSold;
        cDelta = (collateral[ri] - maxSold).multiplyDecimal(lpDeltaAmount).divideDecimal(totalSupply());
    }

    function _tryRemoveLiquidity(uint256 ri, uint256 lpDeltaAmount)
        internal
        view
        returns (
            uint256 cDelta,
            uint256 deltaSpear,
            uint256 deltaShield,
            uint256 earlyWithdrawFee
        )
    {
        uint256 cDelta0 = _getCDelta(ri, lpDeltaAmount);

        cDelta = cDelta0.multiplyDecimal(1e18 - pRatio(ri));
        earlyWithdrawFee = cDelta0 - cDelta;
        deltaSpear = spearBalance[ri][address(this)].multiplyDecimal(lpDeltaAmount).divideDecimal(totalSupply());
        deltaShield = shieldBalance[ri][address(this)].multiplyDecimal(lpDeltaAmount).divideDecimal(totalSupply());
    }

    function _removeLiquidity(uint256 ri, uint256 lpDeltaAmount) internal returns (uint256, uint256) {
        (uint256 cDelta, uint256 deltaSpear, uint256 deltaShield, ) = _tryRemoveLiquidity(ri, lpDeltaAmount);
        uint256 cDeltaSpear = cSpear[ri].multiplyDecimal(lpDeltaAmount).divideDecimal(totalSupply());
        uint256 cDeltaShield = cShield[ri].multiplyDecimal(lpDeltaAmount).divideDecimal(totalSupply());
        subCSpear(ri, cDeltaSpear);
        subCShield(ri, cDeltaShield);
        if (cDeltaSpear + cDeltaShield >= cDelta) {
            addCSurplus(ri, cDeltaSpear + cDeltaShield - cDelta);
        } else {
            subCSurplus(ri, cDelta - cDeltaSpear - cDeltaShield);
        }
        burnSpear(ri, address(this), deltaSpear);
        burnShield(ri, address(this), deltaShield);
        _burn(msg.sender, lpDeltaAmount);

        emit CollateralUpdated(ri, cSpear[ri], cShield[ri], cSurplus(ri));

        return (cDelta, lpDeltaAmount);
    }

    // penalty ratio
    function pRatio(uint256 ri) public view returns (uint256 ratio) {
        if (spearSold(ri) == 0 && shieldSold(ri) == 0) {
            return 0;
        }
        uint256 s = 1e18 - (endTS[ri] - block.timestamp).divideDecimal(endTS[ri] - startTS[ri]);
        ratio = (DMath.sqrt(s) * 1e9).multiplyDecimal(1e16);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(block.timestamp >= lockTS[from], "Locking");
        require(block.timestamp >= lockTS[to], "Locking");
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterAddLiquidity(uint256 ri, uint256 cDeltaAmount) internal virtual {}

    function _afterRemoveLiquidity(uint256 ri, uint256 lpDeltaAmount) internal virtual {}
}
