// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BattleReady.sol";
import "./interfaces/IArena.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
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

contract Battle is BattleReady, Ownable {
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    uint constant PRICE_SETTING_PERIOD=600;
    uint constant LP_LOCK_PERIOD=1800;

    address public feeTo;
    uint public feeRatio;

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

    uint public nextRoundSpearPrice;
    uint public preLPAmount;

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
    }

    function roundIdsLen() external view returns(uint l) {
        l = roundIds.length;
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

    function setNextRoundSpearPrice(uint price) public {
        require(block.timestamp <= endTS[cri]-PRICE_SETTING_PERIOD, "too late");
        uint amount = balanceOf(msg.sender);
        require( amount >= preLPAmount, "not enough lp");
        require(price < 1e18, "price error");
        spearStartPrice = price;
        shieldStartPrice = 1e18 - price;
        // lock user's lp untill next round
        // if in the next round will not
        if (priceMan != address(0) && block.timestamp < lockTS[priceMan]-LP_LOCK_PERIOD) {
            lockTS[priceMan] = 0;
        }
        lockTS[msg.sender] = endTS[cri]+LP_LOCK_PERIOD;
        priceMan = msg.sender;
        preLPAmount = amount;
        emit SetVPrice(msg.sender, spearStartPrice, shieldStartPrice);
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
    function tryBuyShield(uint cDeltaAmount) public view returns(uint){
        return tryBuyShield(cri, cDeltaAmount);
    }

    function buyShield(uint cDeltaAmount) public handleHistoryVirtual addUserRoundId(msg.sender) {
        uint fee = cDeltaAmount.multiplyDecimal(feeRatio);
        buyShield(cri, cDeltaAmount-fee);
        collateralToken.safeTransferFrom(msg.sender, address(this), cDeltaAmount-fee); 
        collateralToken.safeTransferFrom(msg.sender, feeTo, fee);
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

    function removeLiquidityFuture(uint256 lpDeltaAmount) external {
        uint bal = balanceOf(msg.sender);
        require(bal >= lpDeltaAmount, "Not Enough LP");
        // (uint start, ) = oracle.getNextRoundTS(uint(peroidType));
        removeAppointment[cri][msg.sender] += bal;
        totalRemoveAppointment[cri] += bal;
        if (!userAppoint[msg.sender].contains(cri)) {
            userAppoint[msg.sender].add(cri);
        }
        transferFrom(msg.sender, address(this), lpDeltaAmount);
    }

    function withdrawLiquidityHistory() public {
        uint totalC;
        uint len = userAppoint[msg.sender].length(); 
        require( len != 0, "Not Appointment");
        for (uint i; i < len; i++) {
            uint ri = userAppoint[msg.sender].at(i);
            totalC += aCols[ri].multiplyDecimal(removeAppointment[ri][msg.sender]).divideDecimal(totalRemoveAppointment[ri]);
        }
        collateralToken.safeTransfer(msg.sender, totalC);
    }

    function settle() public {
        require(block.timestamp >= endTS[cri], "too early");
        require(roundResult[cri] == RoundResult.Non, "settled");
        uint256 price = oracle.historyPrice(underlying, endTS[cri]);
        require(price != 0, "price error");
        preLPAmount = 0;
        endPrice[cri] = price;
        updateRoundResult();
        // handle collateral
        (uint256 cRemain, uint aCol) = getCRemain();
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


    // function getBattleInfo() public view returns(BattleInfo memory) {
    //     return BattleInfo({
    //         underlying: underlying ,
    //         collateral: address(collateralToken),
    //         peroidType: peroidType,
    //         settleType: settleType,
    //         settleValue: settleValue,
    //         feeRatio: feeRatio
    //     });
    // }

    // function getCurrentRoundInfo() public view returns(RoundInfo memory) {
    //     return getRoundInfo(cri);
    // }

    // function getRoundInfo(uint ri) public view returns(RoundInfo memory) {
    //     return RoundInfo({
    //         spearPrice: spearPrice(ri),
    //         shieldPrice: shieldPrice(ri),
    //         strikePrice: strikePrice[ri],
    //         strikePriceOver: strikePriceOver[ri],
    //         strikePriceUnder: strikePriceUnder[ri],
    //         startTS: startTS[ri],
    //         endTS: endTS[ri]
    //     });
    // }

    // function getRoundInfoMulti(uint[] memory ris) external view returns(RoundInfo[] memory roundInfos) {
    //     for (uint i; i < ris.length; i++) {
    //         RoundInfo memory roundInfo = getRoundInfo(ris[i]);
    //         roundInfos[i] = roundInfo;
    //     }
    // }

    // function getUserInfo(address user, uint ri) public view returns(UserInfo memory) {
    //     return UserInfo({
    //         roundId: ri,
    //         spearBalance: spearBalance[ri][user],
    //         shieldBalance: shieldBalance[ri][user]
    //     });
    // }

    // function getUserInfoMulti(address user, uint[] memory ris) public view returns(UserInfo[] memory uis) {
    //     for (uint i; i < ris.length; i++) {
    //         UserInfo memory ui = getUserInfo(user, ris[i]); 
    //         uis[i] = ui;
    //     }
    // }

    // function getUserInfoAll(address user) public view returns(UserInfo[] memory uis) {
    //     for (uint i; i < userRoundIds[user].length(); i++ ) {
    //         UserInfo memory ui = getUserInfo(user, userRoundIds[user].at(i)); 
    //         uis[i] = ui;
    //     }
    // }

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

    function getUserInfoMulti(address user, uint[] memory ris) public view returns(UserInfo[] memory) {
        uint len = ris.length;
        UserInfo[] memory uis = new UserInfo[](len);
        for (uint i; i < ris.length; i++) {
            UserInfo memory ui = getUserInfo(user, ris[i]); 
            uis[i] = ui;
        }
        return uis;
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

    event SetVPrice(address acc, uint spearPrice, uint shieldPrice);

}
