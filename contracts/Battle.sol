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
import "./structs/RoundInfo.sol";
import "./structs/BattleInfo.sol";
import "./structs/UserInfo.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Battle is BattleReady, Ownable, Initializable {
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    address public feeTo;
    uint public feeRatio;

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
    mapping(address => EnumerableSet.UintSet) internal userRoundIds;

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
    ) public initializer addUserRoundId(creater) {
        spearStartPrice = _spearPrice;
        shieldStartPrice = _shieldPrice;
        initNewRound(cAmount);
        enterRoundId[creater] = cri;
        _mint(creater, cAmount);
    }

    function setArena(address _arena) public onlyOwner {
        arena = IArena(_arena);
    }

    function setFeeTo(address _feeTo) public onlyOwner {
        feeTo = _feeTo;
    }

    function setFeeRatio(uint _feeRatio) public onlyOwner {
        feeRatio = _feeRatio;
    }

    function tryBuySpear(uint cDeltaAmount) public view returns(uint) {
        return tryBuySpear(cri, cDeltaAmount);
    }

    function buySpear(uint256 cDeltaAmount) public handleHistoryVirtual addUserRoundId(msg.sender){
        uint fee = cDeltaAmount.multiplyDecimal(feeRatio);
        buySpear(cri, cDeltaAmount-fee);
        collateralToken.safeTransferFrom(
            msg.sender,
            address(this),
            cDeltaAmount-fee
        );
        collateralToken.safeTransferFrom(msg.sender, feeTo, fee);
    }

    function trySellSpear(uint vDeltaAmount) public view returns(uint) {
        return trySellSpear(cri, vDeltaAmount);
    }

    function sellSpear(uint256 vDeltaAmount) public handleHistoryVirtual{
        uint256 out = sellSpear(cri, vDeltaAmount);
        uint fee = out.multiplyDecimal(feeRatio);
        collateralToken.safeTransfer(msg.sender, out-fee);
        collateralToken.safeTransfer(feeTo, fee);
    }

    function buyShield(uint cDeltaAmount) public handleHistoryVirtual addUserRoundId(msg.sender) {
        uint fee = cDeltaAmount.multiplyDecimal(feeRatio);
        buyShield(cri, cDeltaAmount-fee);
        collateralToken.safeTransferFrom(msg.sender, address(this), cDeltaAmount-fee); 
        collateralToken.safeTransferFrom(msg.sender, feeTo, fee);
    }

    function tryBuyShield(uint cDeltaAmount) public view returns(uint){
        return tryBuyShield(cri, cDeltaAmount);
    }

    function trySellShield(uint vDeltaAmount) public view returns(uint) {
        return trySellShield(cri, vDeltaAmount);
    }

    function sellShield(uint vDeltaAmount) public handleHistoryVirtual {
        uint out = sellShield(cri, vDeltaAmount);
        uint fee = out.multiplyDecimal(feeRatio);
        collateralToken.safeTransfer(msg.sender, out-fee);
        collateralToken.safeTransfer(feeTo, fee);
    }

    function tryAddLiquidity(uint cDeltaAmount) public view returns(uint cDeltaSpear, uint cDeltaShield, uint deltaSpear, uint deltaShield, uint lpDelta) {
        return tryAddLiquidity(cri, cDeltaAmount);
    }

    function addLiquidity(uint256 cDeltaAmount) public addUserRoundId(msg.sender){
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

    // uri => userRoundId
    // rr => roundResult
    function tryClaim(address user) public view returns(uint uri, RoundResult rr, uint amount) {
        uri = enterRoundId[user];
        rr = roundResult[uri];
        if (uri != 0 && uri < cri) {
            if (rr == RoundResult.SpearWin) {
                amount = spearBalance[uri][user];
            } else if (rr == RoundResult.ShieldWin) {
                amount = shieldBalance[uri][user];
            }
        }
    }

    function claim() public {
        (uint uri, RoundResult rr, uint amount) = tryClaim(msg.sender);
        require(amount != 0, "User not spear or shield to claim");
        burnSpear(uri, msg.sender, amount);
        burnShield(uri, msg.sender, amount);
        delete enterRoundId[msg.sender];
        collateralToken.safeTransfer(msg.sender, amount);
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

    function getBattleInfo() public view returns(BattleInfo memory) {
        return BattleInfo({
            trackName: trackName ,
            priceName: priceName,
            peroidType: peroidType,
            settleType: settleType,
            settleValue: settleValue
        });
    }

    function getCurrentRoundInfo() public view returns(RoundInfo memory) {
        return getRoundInfo(cri);
    }

    function getRoundInfo(uint ri) public view returns(RoundInfo memory) {
        return RoundInfo({
            spearPrice: spearPrice(ri),
            shieldPrice: shieldPrice(ri),
            strikePrice: strikePrice[ri],
            strikePriceOver: strikePriceOver[ri],
            strikePriceUnder: strikePriceUnder[ri],
            startTS: startTS[ri],
            endTS: endTS[ri]
        });
    }

    function getUserInfo(address user) public view returns(UserInfo memory) {
        // EnumerableSet.UintSet storage userRound = userRoundIds[user];
        // for (uint i; i < userRoundIds[user].length(); i++) {
        //     uint ri = userRoundIds[user].at(i);
        //     ui.roundIds.push(ri);
        //     // ui.spearBalances.push(spearBalance[ri]);
        //     // ui.shieldBalance.push(shieldBalance[ri]);
        // }
        // return ui;
    }

    modifier addUserRoundId(address user) {
        if(!userRoundIds[user].contains(cri)) {
            userRoundIds[user].add(cri);
        }
        _;
    }

    modifier handleHistoryVirtual() {
        if (enterRoundId[msg.sender] != 0) {
            claim();
        }
        _;
    }

}
