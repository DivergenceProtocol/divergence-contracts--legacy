// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BattleLP.sol";
import "./interfaces/IArena.sol";
import "./structs/SettleType.sol";
import "./structs/PeroidType.sol";
import "./structs/RoundResult.sol";
import "./lib/SafeDecimalMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./structs/RoundInfo.sol";
import "./structs/BattleInfo.sol";
import "./structs/UserInfo.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IOracle.sol";
import "./lib/DMath.sol";
import "hardhat/console.sol";

contract Battle is BattleLP {
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    uint constant PRICE_SETTING_PERIOD=600;
    uint constant LP_LOCK_PERIOD=1800;

    address public feeTo;
    // uint public feeRatio;
    uint stakeFeeRatio;

    uint256 public cri;
    uint256[] public roundIds;


    IArena public arena;
    IERC20 public collateralToken;

    string public underlying;

    PeroidType public peroidType;
    SettleType public settleType;
    uint256 public settleValue;

    uint256 public spearStartPrice;
    uint256 public shieldStartPrice;

    mapping(address => uint256) public enterRoundId;
    mapping(address => EnumerableSet.UintSet) internal userRoundIds;

    // uint public nextRoundSpearPrice;
    uint public lpForAdjustPrice;

    IOracle public oracle;
    bool public isInit0;
    bool public isInit;

    mapping(uint=>mapping(address=>uint)) public removeAppointment;
    mapping(uint=>uint) public totalRemoveAppointment;
    mapping(uint=>uint) public aCols; // appointmentCollateral
    // mapping(address=>uint[]) public userAppoint;
    mapping(address => EnumerableSet.UintSet) internal userAppoint;

    // lock lp to set next round spear price
    // mapping(address => uint) public lockAmount;
    // mapping(address => uint) public lockTS;
    address public priceMan;

    uint public settleReward;

    // ==============view================

    // ris: roundIds
    function expiryExitRis(address account) external view  returns(uint[] memory) {
        uint len = userAppoint[account].length();
        uint[] memory ris = new uint[](len);
        for(uint i; i < len; i++) {
            ris[i] = userAppoint[account].at(i);
        }
        return ris;
    }

    function init0(
        address _collateral,
        address _arena,
        string memory _underlying,
        PeroidType _peroidType,
        SettleType _settleType,
        uint256 _settleValue
    ) public {
        require(isInit0 == false, "init0");
        isInit0 = true;
        collateralToken = IERC20(_collateral);
        arena = IArena(_arena);
        underlying = _underlying;
        peroidType = _peroidType;
        settleType = _settleType;
        settleValue = _settleValue;

        maxPrice = 0.9999*1e18;
        minPrice = 1e18 - maxPrice;

        
        __ERC20_init("Battle Liquilidity Token", "BLP");

        feeRatio = 3e15;
        stakeFeeRatio = 25e16;
        feeTo = address(0x466043D6644886468E8E0ff36dfAF0060aEE7d37);
    }

    function init(
        address creater,
        uint256 cAmount,
        uint256 _spearPrice,
        uint256 _shieldPrice,
        address _oracle
    ) public addUserRoundId(creater) {
        require(isInit==false, "init");
        oracle = IOracle(_oracle);
        isInit = true;
        spearStartPrice = _spearPrice;
        shieldStartPrice = _shieldPrice;
        initNewRound(cAmount);
        enterRoundId[creater] = cri;
        _mint(creater, cAmount);
        emit AddLiquidity(creater, cAmount);
    }

    function roundIdsLen() external view returns(uint l) {
        l = roundIds.length;
    } 

    function setArena(address _arena) external onlyArena {
        arena = IArena(_arena);
    }

    function setFeeTo(address _feeTo) external onlyArena {
        feeTo = _feeTo;
    }

    function setFeeRatio(uint _feeRatio) external onlyArena {
        feeRatio = _feeRatio;
    }

    function setSettleReward(uint amount) external onlyArena {
        settleReward = amount;
    }

    function setNextRoundSpearPrice(uint price) public {
        require(block.timestamp > lockTS[msg.sender], "had seted");
        require(block.timestamp <= endTS[cri]-PRICE_SETTING_PERIOD, "too late");
        uint amount = balanceOf(msg.sender);
        require(price < 1e18, "price error");
        lockTS[msg.sender] = endTS[cri]+LP_LOCK_PERIOD;
        uint adjustedOldPrice = spearStartPrice.multiplyDecimal(lpForAdjustPrice).divideDecimal(lpForAdjustPrice+amount);
        uint adjustedNewPrice = price.multiplyDecimal(amount).divideDecimal(lpForAdjustPrice+amount);
        spearStartPrice = adjustedNewPrice + adjustedOldPrice;
        shieldStartPrice = 1e18 - spearStartPrice;
        lpForAdjustPrice += amount;
        emit SetVPrice(msg.sender, spearStartPrice, shieldStartPrice);
    }

    function _handleFee(uint fee) internal {
        uint stakingFee = fee.multiplyDecimal(stakeFeeRatio);
        collateralToken.safeTransfer(feeTo, stakingFee);
    }

    function tryBuySpear(uint cDeltaAmount) public view returns(uint) {
        (uint out, uint fee) = _tryBuy(cri, cDeltaAmount, 0);
        require(out <= spearBalance[cri][address(this)], "Liquidity Not Enough");
        return out;
    }

    function trySellSpear(uint vDeltaAmount) public view returns(uint) {
        (uint out, uint fee) =  _trySell(cri, vDeltaAmount, 0);
        return out;
    }

    function tryBuyShield(uint cDeltaAmount) public view returns(uint){
        (uint out, uint fee) = _tryBuy(cri, cDeltaAmount, 1);
        require(out <= shieldBalance[cri][address(this)], "Liquidity Not Enough");
        return out;
    }

    function trySellShield(uint vDeltaAmount) public view returns(uint) {
        (uint out, uint fee) =  _trySell(cri, vDeltaAmount, 1);
        return out;
    }

    function buySpear(uint256 cDeltaAmount, uint256 outMin, uint deadline) public ensure(deadline) hat needSettle  handleHistoryVirtual addUserRoundId(msg.sender){
        // fee is total 0.3%
        collateralToken.safeTransferFrom(msg.sender, address(this), cDeltaAmount);
        (uint out, uint fee) = _buy(cri, cDeltaAmount, 0, outMin);
        _handleFee(fee);
        // todo handle actual out
        enterRoundId[msg.sender] = cri;
        emit BuySpear(msg.sender, cDeltaAmount, outMin);
    }

    function sellSpear(uint256 vDeltaAmount, uint outMin, uint deadline) public ensure(deadline) hat needSettle handleHistoryVirtual addUserRoundId(msg.sender){
        (uint256 out, uint fee) = _sell(cri, vDeltaAmount, 0, outMin);
        collateralToken.safeTransfer(msg.sender, out);
        _handleFee(fee);
        enterRoundId[msg.sender] = cri;
        emit SellSpear(msg.sender, vDeltaAmount, outMin);
    }

    function buyShield(uint cDeltaAmount, uint outMin, uint deadline) public ensure(deadline) hat needSettle handleHistoryVirtual addUserRoundId(msg.sender) {
        collateralToken.safeTransferFrom(msg.sender, address(this), cDeltaAmount);
        (uint out, uint fee) = _buy(cri, cDeltaAmount, 1, outMin);
        _handleFee(fee);
        enterRoundId[msg.sender] = cri;
        emit BuyShield(msg.sender, cDeltaAmount, outMin);
    }


    function sellShield(uint vDeltaAmount, uint outMin, uint deadline) public ensure(deadline) hat needSettle handleHistoryVirtual addUserRoundId(msg.sender){
        (uint out, uint fee) = _sell(cri, vDeltaAmount, 1, outMin);
        collateralToken.safeTransfer(msg.sender, out);
        _handleFee(fee);
        enterRoundId[msg.sender] = cri;
        emit SellShield(msg.sender, vDeltaAmount, outMin);
    }

    function tryAddLiquidity(uint cDeltaAmount) public view returns(uint cDeltaSpear, uint cDeltaShield, uint deltaSpear, uint deltaShield, uint lpDelta) {
        return _tryAddLiquidity(cri, cDeltaAmount);
    }

    function addLiquidity(uint256 cDeltaAmount, uint deadline) public ensure(deadline) needSettle addUserRoundId(msg.sender){
        _addLiquidity(cri, cDeltaAmount);
        collateralToken.safeTransferFrom(
            msg.sender,
            address(this),
            cDeltaAmount
        );
        emit AddLiquidity(msg.sender, cDeltaAmount);
    }

    function tryRemoveLiquidity(uint lpDeltaAmount) public view returns(uint cDelta, uint deltaSpear, uint deltaShield, uint earlyWithdrawFee) {
        return _tryRemoveLiquidity(cri, lpDeltaAmount);
    }

    function removeLiquidity(uint256 lpDeltaAmount, uint deadline) public ensure(deadline) needSettle {
        uint256 cDelta = _removeLiquidity(cri, lpDeltaAmount);
        collateralToken.safeTransfer(msg.sender, cDelta);
        emit RemoveLiquidity(msg.sender, lpDeltaAmount);
    }

    function tryRemoveLiquidityFuture(uint256 lpDeltaAmount) external view returns(uint) {
        return _getCDelta(cri, lpDeltaAmount);
    }

    function removeLiquidityFuture(uint256 lpDeltaAmount) external needSettle{
        uint bal = balanceOf(msg.sender);
        require(bal >= lpDeltaAmount, "Not Enough LP");
        // (uint start, ) = oracle.getNextRoundTS(uint(peroidType));
        removeAppointment[cri][msg.sender] += lpDeltaAmount;
        totalRemoveAppointment[cri] += lpDeltaAmount;
        if (!userAppoint[msg.sender].contains(cri)) {
            userAppoint[msg.sender].add(cri);
        }
        transfer(address(this), lpDeltaAmount);
    }

    function tryWithdrawLiquidityHistory() public view returns(uint){
        uint totalC;
        uint len = userAppoint[msg.sender].length(); 
        for (uint i; i < len; i++) {
            uint ri = userAppoint[msg.sender].at(i);
            if (ri < cri) {
                totalC += aCols[ri].multiplyDecimal(removeAppointment[ri][msg.sender]).divideDecimal(totalRemoveAppointment[ri]);
            }
        }
        return totalC;
    }

    function withdrawLiquidityHistory() public {
        uint totalC = tryWithdrawLiquidityHistory();
        require(totalC != 0, "his liqui 0");
        collateralToken.safeTransfer(msg.sender, totalC);
        emit RemoveLiquidity(msg.sender, totalC);
    }

    function transferSettleReward() internal {
        if (collateral[cri] / 100  > settleReward) {
            // transfer reward
            collateralToken.safeTransfer(msg.sender, settleReward);
            uint deltaCSpear = settleReward.multiplyDecimal(cSpear[cri]).divideDecimal(collateral[cri]);
            uint deltaCShield = settleReward.multiplyDecimal(cShield[cri]).divideDecimal(collateral[cri]);
            uint deltaCSurplus = settleReward.multiplyDecimal(cSurplus(cri)).divideDecimal(collateral[cri]);
            subCSpear(cri, deltaCSpear);
            subCShield(cri, deltaCShield);
            subCSurplus(cri, deltaCSurplus);
        } 
    }

    function settle() public {
        require(block.timestamp >= endTS[cri], "too early");
        require(roundResult[cri] == RoundResult.Non, "settled");
        uint256 price = oracle.historyPrice(underlying, endTS[cri]);
        require(price != 0, "price error");
        lpForAdjustPrice = 0;
        endPrice[cri] = price;
        transferSettleReward();
        updateRoundResult();
        // handle collateral
        (uint256 cRemain, uint aCol) = getCRemain();
        console.log("bal %s, appointment %s", balanceOf(address(this)) / 1e18,  totalRemoveAppointment[cri]/1e18);
        _burn(address(this), totalRemoveAppointment[cri]);
        aCols[cri] = aCol;
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
        (uint uri, , uint amount) = tryClaim(msg.sender);
        if (amount != 0 ) {
            burnSpear(uri, msg.sender, amount);
            burnShield(uri, msg.sender, amount);
            delete enterRoundId[msg.sender];
            collateralToken.safeTransfer(msg.sender, amount);
        }
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
            if (endPrice[cri] >= strikePriceUnder[cri]) {
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

    function getCRemain() internal view returns (uint256 cRemain, uint aCol) {
        // (uint start, ) = oracle.getNextRoundTS(uint(peroidType));
        if (roundResult[cri] == RoundResult.SpearWin) {
            cRemain = collateral[cri] - spearSold(cri);
        } else if (roundResult[cri] == RoundResult.ShieldWin) {
            cRemain = collateral[cri] - shieldSold(cri);
        } else {
            revert("not correct round result");
        }
        aCol = cRemain.multiplyDecimal(totalRemoveAppointment[cri]).divideDecimal(totalSupply());
        cRemain -= aCol;
    }

    function initNewRound(uint256 cAmount) internal {
        (uint256 _startTS, uint256 _endTS) = oracle.getRoundTS(uint(peroidType));
        cri = _startTS;
        roundIds.push(_startTS);
        (
            uint256 _startPrice,
            uint256 _strikePrice,
            uint256 _strikePriceOver,
            uint256 _strikePriceUnder
        ) =
            oracle.getStrikePrice(
                underlying,
                uint(peroidType),
                uint(settleType),
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
            underlying: underlying ,
            collateral: address(collateralToken),
            peroidType: peroidType,
            settleType: settleType,
            settleValue: settleValue,
            feeRatio: feeRatio
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
            endTS: endTS[ri],
            result: roundResult[ri]
        });
    }

    function getRoundInfoMulti(uint[] memory ris) external view returns(RoundInfo[] memory) {
        uint len = ris.length;
        RoundInfo[] memory roundInfos = new RoundInfo[](len);
        for (uint i; i < ris.length; i++) {
            RoundInfo memory roundInfo = getRoundInfo(ris[i]);
            roundInfos[i] = roundInfo;
        }
        return roundInfos;
    }

    function getCurrentUserInfo(address user) external view returns(UserInfo memory) {
        return getUserInfo(user, cri);
    }

    function getUserInfo(address user, uint ri) public view returns(UserInfo memory) {
        return UserInfo({
            roundId: ri,
            spearBalance: spearBalance[ri][user],
            shieldBalance: shieldBalance[ri][user]
        });
    }

    function getUserInfoAll(address user) public view returns(UserInfo[] memory) {
        uint len = userRoundIds[user].length();
        UserInfo[] memory uis = new UserInfo[](len);
        for (uint i=0; i < len; i++ ) {
            UserInfo memory ui = getUserInfo(user, userRoundIds[user].at(i)); 
            uis[i] = ui;
        }
        return uis;
    }

    modifier addUserRoundId(address user) {
        _;
        if(!userRoundIds[user].contains(cri)) {
            userRoundIds[user].add(cri);
        }
    }

    modifier handleHistoryVirtual() {
        if (enterRoundId[msg.sender] != 0) {
            claim();
        }
        _;
    }

    modifier onlyArena() {
        require(msg.sender == address(arena), "Should arena");
        _;
    }

    modifier trySettle() {
        if (block.timestamp >= endTS[cri] && roundResult[cri] == RoundResult.Non) {
            settle();
        }
        _;
    }

    modifier needSettle() {
        require(block.timestamp < endTS[cri] && roundResult[cri] == RoundResult.Non);
        _;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }

    modifier hat() {
        // if now is less than 30min of end, cant execute
        require(block.timestamp < endTS[cri] - 60 || block.timestamp >= endTS[cri], "trade hat");
        _;
    }
    
    event SetVPrice(address acc, uint spearPrice, uint shieldPrice);
    event BuySpear(address sender, uint amountIn, uint amountOut);
    event SellSpear(address sender, uint amountIn, uint amountOut);
    event BuyShield(address sender, uint amountIn, uint amountOut);
    event SellShield(address sender, uint amountIn, uint amountOut);
    event AddLiquidity(address sender, uint amountIn);
    event RemoveLiquidity(address sender, uint amountIn);

}
