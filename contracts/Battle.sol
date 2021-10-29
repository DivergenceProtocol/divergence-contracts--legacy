// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BattleLP.sol";
import "./structs/InitParams.sol";
import "./structs/RoundResult.sol";
import "./interfaces/IOracle.sol";
import "./lib/DMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Battle is BattleLP {
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20Metadata;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public constant PRICE_SETTING_PERIOD = 600;
    uint256 public constant LP_LOCK_PERIOD = 1800;
    uint256 public constant HALT_PERIOD = 1800;

    address public arena;
    IERC20Metadata public collateralToken;
    string public underlying;
    PeriodType public periodType;
    SettleType public settleType;
    uint256 public strikeValue;

    uint256 public spearStartPrice;
    uint256 public shieldStartPrice;

    uint256[] public roundIds;

    address public feeTo;

    IOracle public oracle;

    // round which user buyed spear or shield
    mapping(address => uint256) public claimRI;

    mapping(uint256 => mapping(address => uint256)) public userFutureLP;
    mapping(uint256 => uint256) public roundFutureLP;
    mapping(uint256 => uint256) public roundFutureCol; // appointmentCollateral
    mapping(address => EnumerableSet.UintSet) internal userFutureRI;

    uint256 public lpForAdjustPrice;

    // uint256 public settleReward;
    uint256 public cDecimalDiff;

    // ==============view================

    function cri() public view returns (uint256) {
        return roundIds[roundIds.length - 1];
    }

    // ris: roundIds
    function expiryExitRis(address account) external view returns (uint256[] memory) {
        uint256 len = userFutureRI[account].length();
        uint256[] memory ris = new uint256[](len);
        for (uint256 i; i < len; i++) {
            ris[i] = userFutureRI[account].at(i);
        }
        return ris;
    }

    function init(InitParams memory p) external {
        // __ERC20_init("Divergence Battle LP", "DBLP");
        collateralToken = IERC20Metadata(p._collateral);
        string memory pName;
        if (p._periodType == PeriodType.Day) {
            pName = "Day";
        } else if (p._periodType == PeriodType.Week) {
            pName = "Week";
        } else if (p._periodType == PeriodType.Month) {
            pName = "Month";
        } else {
            revert("period error");
        }
        // string memory sName;
        // if (p._settleType == SettleType.TwoWay) {
        //     sName = "Range";
        // } else if (p._settleType == SettleType.Positive) {
        //     sName = "Bullish";
        // } else if (p._settleType == SettleType.Negative) {
        //     sName = "Bearish";
        // } else if (p._settleType == SettleType.Specific) {
        //     sName = "Fixed Strike";
        // } 
        string memory _symbol = string(abi.encodePacked(p._underlying, "-", collateralToken.symbol(), "-", pName));
        __ERC20_init("Divergence Battle LP", _symbol);


        // setting
        arena = msg.sender;
        underlying = p._underlying;
        periodType = p._periodType;
        settleType = p._settleType;
        strikeValue = p._strikeValue;
        maxPrice = 0.99e18;
        minPrice = 1e18 - maxPrice;
        cDecimalDiff = 10**(18 - uint256(collateralToken.decimals()));
        // feeRatio = 3e15;
        // stakeFeeRatio = 25e16;

        feeRatio = 0;
        stakeFeeRatio = 0;

        oracle = IOracle(p._oracle);

        spearStartPrice = p._spearPrice;
        shieldStartPrice = p._shieldPrice;
        _mint(address(1), 10**3);
        uint256 userLPAmount = p._cAmount * cDecimalDiff - 10**3;
        _mint(p.battleCreater, userLPAmount);
        initNewRound(p._cAmount * cDecimalDiff);

        feeTo = p._feeTo;

        uint256 ri = cri();

        emit AddLiquidity(ri, p.battleCreater, p._cAmount, userLPAmount);
    }

    function roundIdsLen() external view returns (uint256 l) {
        l = roundIds.length;
    }

    function setFeeTo(address _feeTo) external onlyArena {
        feeTo = _feeTo;
    }

    function setFeeRatio(uint256 _feeRatio) external onlyArena {
        uint256 oldFeeRatio = feeRatio;
        feeRatio = _feeRatio;
        emit FeeRatioChanged(oldFeeRatio, feeRatio);
    }

    // function setSettleReward(uint256 amount) external onlyArena {
    //     settleReward = amount;
    // }

    function setNextRoundSpearPrice(uint256 price) external handleClaim {
        require(block.timestamp > lockTS[msg.sender], "had seted");
        require(block.timestamp <= endTS[cri()] - PRICE_SETTING_PERIOD, "too late");
        uint256 amount = balanceOf(msg.sender);
        require(price < 1e18, "price error");
        lockTS[msg.sender] = endTS[cri()] + LP_LOCK_PERIOD;
        uint256 adjustedOldPrice = spearStartPrice.multiplyDecimal(lpForAdjustPrice).divideDecimal(lpForAdjustPrice + amount);
        uint256 adjustedNewPrice = price.multiplyDecimal(amount).divideDecimal(lpForAdjustPrice + amount);
        spearStartPrice = adjustedNewPrice + adjustedOldPrice;
        shieldStartPrice = 1e18 - spearStartPrice;
        lpForAdjustPrice += amount;
    }

    function _handleStakeFee(uint256 stakeFee) internal {
        collateralToken.safeTransfer(feeTo, stakeFee / cDecimalDiff);
    }

    function tryBuySpear(uint256 cDeltaAmount) external view returns (uint256) {
        (uint256 out, ,) = _tryBuy(cri(), cDeltaAmount * cDecimalDiff, 0);
        require(out <= spearBalance[cri()][address(this)], "Liquidity Not Enough");
        return out;
    }

    function trySellSpear(uint256 vDeltaAmount) external view returns (uint256) {
        (uint256 out, ,) = _trySell(cri(), vDeltaAmount, 0);
        return out / cDecimalDiff;
    }

    function tryBuyShield(uint256 cDeltaAmount) external view returns (uint256) {
        (uint256 out, ,) = _tryBuy(cri(), cDeltaAmount * cDecimalDiff, 1);
        require(out <= shieldBalance[cri()][address(this)], "Liquidity Not Enough");
        return out;
    }

    function trySellShield(uint256 vDeltaAmount) external view returns (uint256) {
        (uint256 out, ,) = _trySell(cri(), vDeltaAmount, 1);
        return out / cDecimalDiff;
    }

    function buySpear(
        uint256 cDeltaAmount,
        uint256 outMin,
        uint256 deadline
    ) external ensure(deadline) halt needSettle handleClaim {
        // fee is total 0.3%
        (uint256 out, , uint256 stakeFee) = _buy(cri(), cDeltaAmount * cDecimalDiff, 0, outMin);
        claimRI[msg.sender] = cri();
        collateralToken.safeTransferFrom(msg.sender, address(this), cDeltaAmount);
        _handleStakeFee(stakeFee);
        emit BuySpear(cri(), msg.sender, cDeltaAmount, out);
    }

    function sellSpear(
        uint256 vDeltaAmount,
        uint256 outMin,
        uint256 deadline
    ) external ensure(deadline) halt needSettle handleClaim {
        (uint256 out, uint256 fee, uint256 stakeFee) = _sell(cri(), vDeltaAmount, 0, outMin * cDecimalDiff);
        uint256 outDecimalDiff = out / cDecimalDiff;
        collateralToken.safeTransfer(msg.sender, outDecimalDiff);
        _handleStakeFee(stakeFee);
        emit SellSpear(cri(), msg.sender, vDeltaAmount, (out+fee)/cDecimalDiff);
    }

    function buyShield(
        uint256 cDeltaAmount,
        uint256 outMin,
        uint256 deadline
    ) external ensure(deadline) halt needSettle handleClaim {
        (uint256 out, , uint256 stakeFee) = _buy(cri(), cDeltaAmount * cDecimalDiff, 1, outMin);
        claimRI[msg.sender] = cri();
        collateralToken.safeTransferFrom(msg.sender, address(this), cDeltaAmount);
        _handleStakeFee(stakeFee);
        emit BuyShield(cri(), msg.sender, cDeltaAmount, out);
    }

    function sellShield(
        uint256 vDeltaAmount,
        uint256 outMin,
        uint256 deadline
    ) external ensure(deadline) halt needSettle handleClaim {
        (uint256 out, uint256 fee, uint256 stakeFee) = _sell(cri(), vDeltaAmount, 1, outMin * cDecimalDiff);
        uint256 outDecimalDiff = out / cDecimalDiff;
        collateralToken.safeTransfer(msg.sender, outDecimalDiff);
        _handleStakeFee(stakeFee);
        // out is just user can get
        emit SellShield(cri(), msg.sender, vDeltaAmount, (out+fee)/cDecimalDiff);
    }

    function tryAddLiquidity(uint256 cDeltaAmount)
        external
        view
        returns (
            uint256 cDeltaSpear,
            uint256 cDeltaShield,
            uint256 deltaSpear,
            uint256 deltaShield,
            uint256 lpDelta
        )
    {
        return _tryAddLiquidity(cri(), cDeltaAmount * cDecimalDiff);
    }

    function addLiquidity(uint256 cDeltaAmount, uint256 deadline) public ensure(deadline) needSettle handleClaim {
        uint256 lpDelta = _addLiquidity(cri(), cDeltaAmount * cDecimalDiff);
        collateralToken.safeTransferFrom(msg.sender, address(this), cDeltaAmount);
        emit AddLiquidity(cri(), msg.sender, cDeltaAmount, lpDelta);
    }

    function tryRemoveLiquidity(uint256 lpDeltaAmount)
        external
        view
        returns (
            uint256 cDelta,
            uint256 deltaSpear,
            uint256 deltaShield,
            uint256 earlyWithdrawFee
        )
    {
        (cDelta, deltaSpear, deltaShield, earlyWithdrawFee) = _tryRemoveLiquidity(cri(), lpDeltaAmount);
        cDelta /= cDecimalDiff;
        earlyWithdrawFee /= cDecimalDiff;
    }

    function removeLiquidity(uint256 lpDeltaAmount, uint256 deadline) external ensure(deadline) needSettle handleClaim {
        (uint256 cDelta, uint256 lpDelta) = _removeLiquidity(cri(), lpDeltaAmount);
        uint256 cDeltaDD = cDelta / cDecimalDiff;
        collateralToken.safeTransfer(msg.sender, cDeltaDD);
        emit RemoveLiquidity(cri(), msg.sender, cDeltaDD, lpDelta);
    }

    function tryRemoveLiquidityFuture(uint256 lpDeltaAmount) external view returns (uint256) {
        return _getCDelta(cri(), lpDeltaAmount) / cDecimalDiff;
    }

    function removeLiquidityFuture(uint256 lpDeltaAmount) external needSettle handleClaim {
        uint256 bal = balanceOf(msg.sender);
        require(bal >= lpDeltaAmount, "Not Enough LP");
        userFutureLP[cri()][msg.sender] += lpDeltaAmount;
        roundFutureLP[cri()] += lpDeltaAmount;
        if (!userFutureRI[msg.sender].contains(cri())) {
            userFutureRI[msg.sender].add(cri());
        }
        transfer(address(this), lpDeltaAmount);
        emit RemoveLiquidityFuture(cri(), msg.sender, lpDeltaAmount);
    }

    function tryWithdrawLiquidityHistory(address account) external view returns (uint256, uint256) {
        uint256 totalC;
        uint256 totalLP;
        uint256 len = userFutureRI[account].length();
        for (uint256 i; i < len; i++) {
            uint256 ri = userFutureRI[account].at(i);
            if (ri < cri()) {
                totalC += roundFutureCol[ri].multiplyDecimal(userFutureLP[ri][account]).divideDecimal(roundFutureLP[ri]);
                totalLP += userFutureLP[ri][account];
            }
        }
        return (totalC / cDecimalDiff, totalLP);
    }

    function withdrawLiquidityHistory() external handleClaim {
        uint256 totalC;
        uint256 totalLP;
        uint256 len = userFutureRI[msg.sender].length();
        for (uint256 i; i < len; i++) {
            uint256 ri = userFutureRI[msg.sender].at(i);
            if (ri < cri()) {
                uint256 col = roundFutureCol[ri].multiplyDecimal(userFutureLP[ri][msg.sender]).divideDecimal(roundFutureLP[ri]);
                totalC += col;
                uint256 lp = userFutureLP[ri][msg.sender];
                totalLP += lp;
                emit WithdrawFutureLiquidity(ri, col, lp);
            }
        }
        require(totalC != 0, "history liquidity 0");
        for (uint256 i; i < len; i++) {
            uint256 ri = userFutureRI[msg.sender].at(i);
            if (ri < cri()) {
                userFutureRI[msg.sender].remove(ri);
                roundFutureLP[ri] -= userFutureLP[ri][msg.sender];
                delete userFutureLP[ri][msg.sender];
            }
        }
        uint256 totalCDD = totalC / cDecimalDiff;
        collateralToken.safeTransfer(msg.sender, totalCDD);
        emit RemoveLiquidity(cri(), msg.sender, totalCDD, totalLP);
    }

    // function transferSettleReward() internal {
    //     if (collateral[cri()] / 100 > settleReward && settleReward > 0) {
    //         // transfer reward
    //         collateralToken.safeTransfer(msg.sender, settleReward);
    //         uint256 deltaCSpear = settleReward * cDecimalDiff.multiplyDecimal(cSpear[cri()]).divideDecimal(collateral[cri()]);
    //         uint256 deltaCShield = settleReward * cDecimalDiff.multiplyDecimal(cShield[cri()]).divideDecimal(collateral[cri()]);
    //         uint256 deltaCSurplus = settleReward * cDecimalDiff.multiplyDecimal(cSurplus(cri())).divideDecimal(collateral[cri()]);
    //         subCSpear(cri(), deltaCSpear);
    //         subCShield(cri(), deltaCShield);
    //         subCSurplus(cri(), deltaCSurplus);
    //     }
    // }

    function settle() public {
        require(block.timestamp >= endTS[cri()], "too early");
        require(roundResult[cri()] == RoundResult.Non, "settled");
        uint256 price = oracle.updatePriceByExternal(underlying, endTS[cri()]);
        require(price != 0, "price error");
        uint256 oldRI = cri();
        lpForAdjustPrice = 0;
        endPrice[cri()] = price;
        // transferSettleReward();
        uint256 result = updateRoundResult();
        // handle collateral
        (uint256 cRemain, uint256 futureCol) = getCRemain();
        if (roundFutureLP[cri()] > 0) {
            _burn(address(this), roundFutureLP[cri()]);
        }
        roundFutureCol[cri()] = futureCol;
        initNewRound(cRemain);
        emit Settled(oldRI, price, result);
    }

    // uri => userRoundId
    // rr => roundResult
    function tryClaim(address user)
        public
        view
        returns (
            uint256 uri,
            RoundResult rr,
            uint256 amount
        )
    {
        uri = claimRI[user];
        if (uri != 0) {
            rr = roundResult[uri];
            if (uri < cri()) {
                if (rr == RoundResult.SpearWin) {
                    amount = spearBalance[uri][user];
                } else if (rr == RoundResult.ShieldWin) {
                    amount = shieldBalance[uri][user];
                }
            }
            amount /= cDecimalDiff;
        }
    }

    function claim() public {
        (uint256 uri, RoundResult rr, uint256 amount) = tryClaim(msg.sender);
        if (amount != 0) {
            if (rr == RoundResult.SpearWin) {
                burnSpear(uri, msg.sender, amount * cDecimalDiff);
                emit Claimed(uri, 0, msg.sender, amount * cDecimalDiff);
            } else if (rr == RoundResult.ShieldWin) {
                burnShield(uri, msg.sender, amount * cDecimalDiff);
                emit Claimed(uri, 1, msg.sender, amount * cDecimalDiff);
            } else {
                revert("error");
            }
            delete claimRI[msg.sender];
            collateralToken.safeTransfer(msg.sender, amount);
        }
    }

    function updateRoundResult() internal returns (uint256 result) {
        if (settleType == SettleType.TwoWay) {
            if (endPrice[cri()] >= strikePriceOver[cri()] || endPrice[cri()] <= strikePriceUnder[cri()]) {
                roundResult[cri()] = RoundResult.SpearWin;
            } else {
                roundResult[cri()] = RoundResult.ShieldWin;
            }
        } else if (settleType == SettleType.Positive) {
            if (endPrice[cri()] >= strikePriceOver[cri()]) {
                roundResult[cri()] = RoundResult.SpearWin;
            } else {
                roundResult[cri()] = RoundResult.ShieldWin;
            }
        } else if (settleType == SettleType.Negative) {
            if (endPrice[cri()] >= strikePriceUnder[cri()]) {
                roundResult[cri()] = RoundResult.SpearWin;
            } else {
                roundResult[cri()] = RoundResult.ShieldWin;
            }
        } else if (settleType == SettleType.Specific) {
            if (endPrice[cri()] >= strikePrice[cri()]) {
                roundResult[cri()] = RoundResult.SpearWin;
            } else {
                roundResult[cri()] = RoundResult.ShieldWin;
            }
        } else {
            revert("unknown settle type");
        }
        result = uint256(roundResult[cri()]);
    }

    function getCRemain() internal view returns (uint256 cRemain, uint256 futureCol) {
        // (uint start, ) = oracle.getNextRoundTS(uint(periodType));
        if (roundResult[cri()] == RoundResult.SpearWin) {
            cRemain = collateral[cri()] - spearSold(cri());
        } else if (roundResult[cri()] == RoundResult.ShieldWin) {
            cRemain = collateral[cri()] - shieldSold(cri());
        } else {
            revert("not correct round result");
        }
        futureCol = cRemain.multiplyDecimal(roundFutureLP[cri()]).divideDecimal(totalSupply());
        cRemain -= futureCol;
    }

    function initNewRound(uint256 cAmount) internal {
        (uint256 _startTS, uint256 _endTS) = oracle.getRoundTS(periodType);
        oracle.updatePriceByExternal(underlying, _startTS);
        roundIds.push(_startTS);
        (uint256 _startPrice, uint256 _strikePrice, uint256 _strikePriceOver, uint256 _strikePriceUnder) = oracle.getStrikePrice(underlying, periodType, settleType, strikeValue);
        mintSpear(cri(), address(this), cAmount);
        mintShield(cri(), address(this), cAmount);
        addCSpear(cri(), spearStartPrice.multiplyDecimal(cAmount));
        addCShield(cri(), shieldStartPrice.multiplyDecimal(cAmount));
        // startPrice endPrice
        startPrice[cri()] = _startPrice;
        startTS[cri()] = _startTS;
        endTS[cri()] = _endTS;
        strikePrice[cri()] = _strikePrice;
        strikePriceOver[cri()] = _strikePriceOver;
        strikePriceUnder[cri()] = _strikePriceUnder;
        roundResult[cri()] = RoundResult.Non;
        emit NewRound(cri(), _endTS, spearStartPrice, shieldStartPrice, _strikePrice, _strikePriceOver, _strikePriceUnder, cAmount / cDecimalDiff, totalSupply());
    }

    modifier handleClaim() {
        if (claimRI[msg.sender] != 0) {
            claim();
        }
        _;
    }

    modifier onlyArena() {
        require(msg.sender == arena, "Should arena");
        _;
    }

    modifier trySettle() {
        if (block.timestamp >= endTS[cri()] && roundResult[cri()] == RoundResult.Non) {
            settle();
        }
        _;
    }

    modifier needSettle() {
        require(block.timestamp < endTS[cri()] && roundResult[cri()] == RoundResult.Non);
        _;
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "EXPIRED");
        _;
    }

    modifier halt() {
        // if now is less than 30min of end, cant execute
        require(block.timestamp < endTS[cri()] - HALT_PERIOD || block.timestamp >= endTS[cri()], "trade halt");
        _;
    }

    event NewRound(uint256 ri, uint256 endTS, uint256 spearPrice, uint256 shieldPrice, uint256 strikePrice, uint256 strikePriceOver, uint256 strikePriceUnder, uint256 cAmount, uint256 lpAmount);
    event BuySpear(uint256 ri, address sender, uint256 amountIn, uint256 amountOut);
    event SellSpear(uint256 ri, address sender, uint256 amountIn, uint256 amountOut);
    event BuyShield(uint256 ri, address sender, uint256 amountIn, uint256 amountOut);
    event SellShield(uint256 ri, address sender, uint256 amountIn, uint256 amountOut);
    event AddLiquidity(uint256 ri, address sender, uint256 cAmount, uint256 lpAmount);
    event RemoveLiquidity(uint256 ri, address sender, uint256 cAmount, uint256 lpAmount);
    event Settled(uint256 ri, uint256 settlePrice, uint256 result);
    event Claimed(uint256 ri, uint256 spearOrShield, address account, uint256 amount);
    event RemoveLiquidityFuture(uint256 ri, address account, uint256 lpAmount);
    event WithdrawFutureLiquidity(uint256 ri, uint256 collateral, uint256 lp);
    event FeeRatioChanged(uint256 oldFeeRatio, uint256 newFeeRatio);
}
