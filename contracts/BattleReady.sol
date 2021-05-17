// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BondingCurve.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./lib/SafeDecimalMath.sol";
import "./structs/RoundResult.sol";

contract BattleReady is BondingCurve, ERC20 {

    using SafeDecimalMath for uint;

    mapping(uint=>uint) public startPrice;
    mapping(uint=>uint) public endPrice;

    mapping(uint=>uint) public startTS;
    mapping(uint=>uint) public endTS;

    mapping(uint=>uint) public strikePrice;
    mapping(uint=>uint) public strikePriceOver;
    mapping(uint=>uint) public strikePriceUnder;

    mapping(uint=>RoundResult) public roundResult;

    constructor() ERC20("Battle Liquilidity Token", "BLP") {

    }

    function tryAddLiquidity(uint ri, uint cDeltaAmount) public view returns(uint cDeltaSpear, uint cDeltaShield, uint deltaSpear, uint deltaShield, uint lpDelta) {
        uint cVirtual = cSpear[ri] + cShield[ri];
        cDeltaSpear = cSpear[ri].multiplyDecimal(cDeltaAmount).divideDecimal(cVirtual);
        cDeltaShield = cShield[ri].multiplyDecimal(cDeltaAmount).divideDecimal(cVirtual);
        deltaSpear = spearBalance[ri][address(this)].multiplyDecimal(cDeltaAmount).divideDecimal(cVirtual);
        deltaShield = shieldBalance[ri][address(this)].multiplyDecimal(cDeltaAmount).divideDecimal(cVirtual);
        if(totalSupply() == 0) {
            lpDelta = cDeltaAmount;
        } else {
            lpDelta = cDeltaAmount.multiplyDecimal(totalSupply()).divideDecimal(collateral[ri]);
        }
    }

    function addLiquidity(uint ri, uint cDeltaAmount) internal {
        (uint cDeltaSpear, uint cDeltaShield, uint deltaSpear, uint deltaShield, uint lpDelta) = tryAddLiquidity(ri, cDeltaAmount);
        addCSpear(ri, cDeltaSpear);
        addCShield(ri, cDeltaShield);
        mintSpear(ri, msg.sender, deltaSpear);
        mintShield(ri, msg.sender, deltaShield);
        // mint lp
        _mint(msg.sender, lpDelta);
    }

    function tryRemoveLiquidity(uint ri, uint lpDeltaAmount) public view returns(uint cDelta, uint deltaSpear, uint deltaShield){
        uint spSold = spearSold(ri);
        uint shSold = shieldSold(ri);
        uint maxSold = spSold > shSold ? spSold:shSold;
        cDelta = (collateral[ri] - maxSold).multiplyDecimal(lpDeltaAmount).divideDecimal(totalSupply());
        deltaSpear = spearBalance[ri][address(this)].multiplyDecimal(lpDeltaAmount).divideDecimal(totalSupply());
        deltaShield = shieldBalance[ri][address(this)].multiplyDecimal(lpDeltaAmount).divideDecimal(totalSupply());
    }

    function removeLiquidity(uint ri, uint lpDeltaAmount) internal returns(uint) {
        (uint cDelta, uint deltaSpear, uint deltaShield) = tryRemoveLiquidity(ri, lpDeltaAmount);
        uint cDeltaSpear = cDelta.multiplyDecimal(cSpear[ri]).divideDecimal(collateral[ri]);
        uint cDeltaShield = cDelta.multiplyDecimal(cShield[ri]).divideDecimal(collateral[ri]);
        uint cDeltaSurplus = cDelta.multiplyDecimal(cSurplus(ri)).divideDecimal(collateral[ri]);
        subCSpear(ri, cDeltaSpear);
        subCShield(ri, cDeltaShield);
        subCSurplus(ri, cDeltaSurplus);
        burnSpear(ri, address(this), deltaSpear);
        burnShield(ri, address(this), deltaShield);
        _burn(msg.sender, lpDeltaAmount);
        return cDelta;
    }

    function _afterAddLiquidity(uint ri, uint cDeltaAmount) internal virtual {}
    function _afterRemoveLiquidity(uint ri, uint lpDeltaAmount) internal virtual {}

}