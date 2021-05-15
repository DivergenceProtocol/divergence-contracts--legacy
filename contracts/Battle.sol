// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BattleReady.sol";
import "./interfaces/IArena.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./structs/SettleType.sol";
import "./structs/PeroidType.sol";
import "./structs/RoundResult.sol";
import "./lib/SafeDecimalMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Battle is BattleReady, Ownable, Initializable {
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public cri;
    uint256[] public roundIds;

    IArena public arena;
    IERC20 public collateralToken;

    string public trackName;
    string public priceName;

    PeroidType public peroidType;
    SettleType public settleType;
    uint256 public settleValue;

    uint256 public spearStartPrice;
    uint256 public shieldStartPrice;

    mapping(address => uint256) public enterRoundId;

    function init0(
        address _collateral,
        address _arena,
        string memory _trackName,
        string memory _priceName,
        PeroidType _peroidType,
        SettleType _settleType,
        uint256 _settleValue
    ) public initializer {
        collateralToken = IERC20(_collateral);
        arena = IArena(_arena);
        trackName = _trackName;
        priceName = _priceName;
        peroidType = _peroidType;
        settleType = _settleType;
        settleValue = _settleValue;
    }

    function init(
        address creater,
        uint256 cAmount,
        uint256 _spearPrice,
        uint256 _shieldPrice
    ) public initializer {
        spearStartPrice = _spearPrice;
        shieldStartPrice = _shieldPrice;
        initNewRound(cAmount);
        enterRoundId[creater] = cri;
        _mint(creater, cAmount);
    }

    function setArena(address _arena) public onlyOwner {
        arena = IArena(_arena);
    }

    function buySpear(uint256 cDeltaAmount) public {
        buySpear(cri, cDeltaAmount);
        collateralToken.safeTransferFrom(
            msg.sender,
            address(this),
            cDeltaAmount
        );
    }

    function tryBuySpear(uint cDeltaAmount) public view returns(uint) {
        return tryBuySpear(cri, cDeltaAmount);
    }

    function sellSpear(uint256 vDeltaAmount) public {
        uint256 out = sellSpear(cri, vDeltaAmount);
        collateralToken.safeTransfer(msg.sender, out);
    }

    function trySellSpear(uint vDeltaAmount) public view returns(uint) {
        return trySellSpear(cri, vDeltaAmount);
    }

    function buyShield(uint cDeltaAmount) public {
        buyShield(cri, cDeltaAmount);
        collateralToken.safeTransferFrom(msg.sender, address(this), cDeltaAmount); 
    }

    function tryBuyShield(uint cDeltaAmount) public view returns(uint){
        return tryBuyShield(cri, cDeltaAmount);
    }

    function tryAddLiquidity(uint cDeltaAmount) public view returns(uint cDeltaSpear, uint cDeltaShield, uint deltaSpear, uint deltaShield) {
        return tryAddLiquidity(cri, cDeltaAmount);
    }

    function addLiquidity(uint256 cDeltaAmount) public {
        addLiquidity(cri, cDeltaAmount);
        collateralToken.safeTransferFrom(
            msg.sender,
            address(this),
            cDeltaAmount
        );
    }

    function tryRemoveLiquidity(uint lpDeltaAmount) public view returns(uint cDelta, uint deltaSpear, uint deltaShield) {
        return tryRemoveLiquidity(cri, lpDeltaAmount);
    }

    function removeLiquidity(uint256 lpDeltaAmount) public {
        uint256 cDelta = removeLiquidity(cri, lpDeltaAmount);
        collateralToken.safeTransfer(msg.sender, cDelta);
    }

    function settle() public {
        require(block.timestamp >= endTS[cri], "too early to settle");
        require(roundResult[cri] == RoundResult.Non, "round already settled");
        uint256 price = arena.getPriceByTS(priceName, endTS[cri]);
        require(price != 0, "price is not correct");
        endPrice[cri] = price;
        updateRoundResult();
        // handle collateral
        uint256 cRemain = getCRemain();
        initNewRound(cRemain);
    }

    function updateRoundResult() internal {
        if (settleType == SettleType.TwoWay) {
            if (
                endPrice[cri] >= strikePriceOver[cri] ||
                endPrice[cri] <= strikePriceUnder[cri]
            ) {
                roundResult[cri] = RoundResult.SpearWin;
            } else {
                roundResult[cri] = RoundResult.ShieldWin;
            }
        } else if (settleType == SettleType.Positive) {
            if (endPrice[cri] >= strikePriceOver[cri]) {
                roundResult[cri] = RoundResult.SpearWin;
            } else {
                roundResult[cri] = RoundResult.ShieldWin;
            }
        } else if (settleType == SettleType.Negative) {
            if (endPrice[cri] <= strikePriceUnder[cri]) {
                roundResult[cri] = RoundResult.SpearWin;
            } else {
                roundResult[cri] = RoundResult.ShieldWin;
            }
        } else if (settleType == SettleType.Specific) {
            if (endPrice[cri] >= strikePrice[cri]) {
                roundResult[cri] = RoundResult.SpearWin;
            } else {
                roundResult[cri] = RoundResult.ShieldWin;
            }
        } else {
            revert("unknown settle type");
        }
    }

    function getCRemain() internal view returns (uint256 cRemain) {
        if (roundResult[cri] == RoundResult.SpearWin) {
            cRemain = collateral[cri] - spearTotal[cri];
        } else if (roundResult[cri] == RoundResult.ShieldWin) {
            cRemain = collateral[cri] - shieldTotal[cri];
        } else {
            revert("not correct round result");
        }
    }

    function initNewRound(uint256 cAmount) internal {
        (uint256 _startTS, uint256 _endTS) = arena.getPeroidTS(peroidType);
        cri = _startTS;
        roundIds.push(_startTS);
        (
            uint256 _startPrice,
            uint256 _strikePrice,
            uint256 _strikePriceOver,
            uint256 _strikePriceUnder
        ) =
            arena.getStrikePrice(
                priceName,
                peroidType,
                settleType,
                settleValue
            );
        mintSpear(cri, address(this), cAmount);
        mintShield(cri, address(this), cAmount);
        addCSpear(cri, spearStartPrice.multiplyDecimal(cAmount));
        addCShield(cri, shieldStartPrice.multiplyDecimal(cAmount));
        // startPrice endPrice
        startPrice[cri] = _startPrice;
        startTS[cri] = _startTS;
        endTS[cri] = _endTS;
        strikePrice[cri] = _strikePrice;
        strikePriceOver[cri] = _strikePriceOver;
        strikePriceUnder[cri] = _strikePriceUnder;
        roundResult[cri] = RoundResult.Non;
    }

    function roundInfo(uint ri) public view returns() {
        
    }
}
