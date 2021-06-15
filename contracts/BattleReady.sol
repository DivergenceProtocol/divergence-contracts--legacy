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

    mapping(address=>uint) public lockTS;

    constructor() ERC20("Battle Liquilidity Token", "BLP") {

    }

    function tryAddLiquidity(uint ri, uint cDeltaAmount) internal view returns(uint cDeltaSpear, uint cDeltaShield, uint deltaSpear, uint deltaShield, uint lpDelta) {
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

    function tryRemoveLiquidity(uint ri, uint lpDeltaAmount) internal view returns(uint cDelta, uint deltaSpear, uint deltaShield){
        uint spSold = spearSold(ri);
        uint shSold = shieldSold(ri);
        uint maxSold = spSold > shSold ? spSold:shSold;
        console.log("maxSold %s", maxSold);
        cDelta = (collateral[ri] - maxSold).multiplyDecimal(lpDeltaAmount).divideDecimal(totalSupply());
        console.log("tryRemoveLiquidity cDelta %s", cDelta);
        cDelta = cDelta.multiplyDecimal(1e18-pRatio(ri));
        console.log("tryRemoveLiquidity cDelta %s", cDelta);
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

    // penalty ratio
    function pRatio(uint ri) public view returns (uint ratio){
        uint s = 1e18 - (endTS[ri]-block.timestamp).divideDecimal(endTS[ri]-startTS[ri]);
        console.log("pRatio %s", s);
        ratio = DMath.sqrt(s).multiplyDecimal(1e16);
        console.log("pRatio ratio %s", ratio);
    }

    function _beforeTokenTransfer(address from, address to, uint amount) internal override {
        require(block.timestamp >= lockTS[from], "Locking");
        require(block.timestamp >= lockTS[to], "Locking");
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterAddLiquidity(uint ri, uint cDeltaAmount) internal virtual {}
    function _afterRemoveLiquidity(uint ri, uint lpDeltaAmount) internal virtual {}

}