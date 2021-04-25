// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IBattle.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./lib/SafeDecimalMath.sol";
import "./lib/DMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IOracle.sol";
import "./structs/RoundInfo.sol";
// import "hardhat/console.sol";

/**@title Battle contains multi-round */
contract Battle is Ownable {
    
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using SafeDecimalMath for uint;
    using DMath for uint;

    IOracle public oracle;

    /// @dev user's lp balance per round
    mapping(uint => mapping(address=>uint)) public lpBalanceOf;
    mapping(uint => uint) public lpTotalSupply;
    /// @dev user's spear balance per round
    mapping(uint => mapping(address=>uint)) public spearBalanceOf;
    mapping(uint => uint) public totalSpear;
    /// @dev user's shield balance per round
    mapping(uint => mapping(address=>uint)) public shieldBalanceOf;
    mapping(uint => uint) public totalShield;
    /// @dev collateral token belong to spear side
    mapping(uint => uint) public collateralSpear;
    /// @dev collateral token belong to shield side
    mapping(uint => uint) public collateralShield;
    /// @dev collateral token belong to non-spear and non-shield
    mapping(uint => uint) public collateralSurplus;
    /// @dev spear amount belong to the battle contract per round
    // mapping(uint => uint) public spearNum;
    /// @dev shield amount belong to the battle contract per round
    // mapping(uint => uint) public shieldNum;
    mapping(uint => uint) public spearPrice;
    mapping(uint => uint) public shieldPrice;
    mapping(address => uint) public userStartRoundSS;
    mapping(address => uint) public userStartRoundLP;

    string public trackName;
    string public priceName;
    
    uint public currentRoundId;
    uint[] public roundIds;
    mapping(uint => RoundInfo) public rounds;

    IERC20 public collateralToken;

    mapping(uint => uint) public sqrt_k_spear;
    mapping(uint => uint) public sqrt_k_shield;

    function roundIdsLen() public view returns(uint) {
        return roundIds.length;
    }

    /// @dev init the battle and set the first round's params
    /// this function will become the start point 
    /// @param amount The amount of collateral, the collateral can be any ERC20 token contract, such as dai
    /// @param _spearPrice Init price of spear
    /// @param _shieldPrice Init price of shield
    /// @param _range The positive and negative range of price changes
    /// @param _startTS The start timestamp of first round
    /// @param _endTS The end timestamp of first round 
    function init(address _collateral, IOracle _oracle, string memory _trackName, string memory _priceName, uint amount, uint _spearPrice, uint _shieldPrice, uint _range, RangeType _ry, uint _startTS, uint _endTS) external {
        collateralToken = IERC20(_collateral);
        oracle = _oracle;
        trackName = _trackName;
        priceName = _priceName;
        require(_spearPrice.add(_shieldPrice) == 1e18, "Battle::init:spear + shield should 1");
        require(block.timestamp <= _startTS, "Battle::_startTS should in future");
        currentRoundId = _startTS;
        roundIds.push(_startTS);
        uint price = oracle.price(priceName);
        uint priceUnder = price.multiplyDecimal(uint(1e18).sub(_range));
        uint priceSuper = price.multiplyDecimal(uint(1e18).add(_range));
        rounds[_startTS] = RoundInfo({
            spearPrice: _spearPrice,
            shieldPrice: _shieldPrice,
            // todo
            startPrice: price,
            endPrice: 0,
            startTS: _startTS,
            endTS: _endTS,
            range: _range,
            ry: _ry,
            targetPriceUnder: priceUnder,
            targetPriceSuper: priceSuper,
            roundResult: RoundResult.NonResult
        });
        spearBalanceOf[currentRoundId][address(this)] = amount;
        totalSpear[currentRoundId] = totalSpear[currentRoundId].add(amount);
        shieldBalanceOf[currentRoundId][address(this)] = amount;
        totalShield[currentRoundId] = totalShield[currentRoundId].add(amount);
        collateralSpear[currentRoundId] = _spearPrice.multiplyDecimal(amount);
        collateralShield[currentRoundId] = _shieldPrice.multiplyDecimal(amount);
        spearPrice[currentRoundId] = _spearPrice;
        shieldPrice[currentRoundId] = _shieldPrice;
        lpBalanceOf[currentRoundId][msg.sender] = amount;
        userStartRoundLP[msg.sender] = currentRoundId;
        lpTotalSupply[currentRoundId] = lpTotalSupply[currentRoundId].add(amount);
        collateralToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @dev The price of spear will not exceed 0.99. When the price is less than 0.99, amm satisfies x*y=k, and when the price exceeds 0.99, it satisfies x+y=k.
    /// @param amount the amount of collateral token, collateral token should a ERC20 token
    /// @dev user has three status: has spear before this round, first this round , not first for this round
    function buySpear(uint amount) external {
        if (userStartRoundSS[msg.sender] < currentRoundId) {
            claim();
        }
        userStartRoundSS[msg.sender] = currentRoundId;
        collateralToken.safeTransferFrom(msg.sender, address(this), amount);
        (uint spearOut, bool isBigger, uint pre_k) = getAmountOut(amount, collateralSpear[currentRoundId], spearBalanceOf[currentRoundId][address(this)], sqrt_k_spear[currentRoundId]);
        sqrt_k_spear[currentRoundId] = pre_k;
        collateralSpear[currentRoundId] = collateralSpear[currentRoundId].add(amount);
        spearBalanceOf[currentRoundId][address(this)] = spearBalanceOf[currentRoundId][address(this)].sub(spearOut);
        spearBalanceOf[currentRoundId][msg.sender] = spearBalanceOf[currentRoundId][msg.sender].add(spearOut);
        if(isBigger) {
            collateralShield[currentRoundId] = shieldBalanceOf[currentRoundId][address(this)].div(100);
        } else {
            collateralShield[currentRoundId] = spearBalanceOf[currentRoundId][address(this)].sub(collateralSpear[currentRoundId])
                                                                                            .multiplyDecimal(shieldBalanceOf[currentRoundId][address(this)])
                                                                                            .divideDecimal(spearBalanceOf[currentRoundId][address(this)]);
        }
        _setPrice();
    }

    function _setPrice() internal {
        uint spearPriceNow= collateralSpear[currentRoundId].divideDecimal(spearBalanceOf[currentRoundId][address(this)]);
        uint shieldPriceNow = collateralShield[currentRoundId].divideDecimal(shieldBalanceOf[currentRoundId][address(this)]);
        if (spearPriceNow >= 99e16 || shieldPriceNow >= 99e16) {
            if(spearPriceNow >= 99e16) {
                spearPrice[currentRoundId] = 99e16;
                shieldPrice[currentRoundId] = 1e16;
            } else {
                spearPrice[currentRoundId] = 1e16;
                shieldPrice[currentRoundId] = 99e16;
            }
        } else {
           spearPrice[currentRoundId] = spearPriceNow; 
           shieldPrice[currentRoundId] = shieldPriceNow;
        }
    }

    function spearSold(uint _roundId) public view returns(uint) {
        return totalSpear[_roundId].sub(spearBalanceOf[_roundId][address(this)]);
    }

    function buySpearOut(uint amount) public view returns(uint) {
        (uint spearOut, bool isBigger, uint pre_k) = getAmountOut(amount, collateralSpear[currentRoundId], spearBalanceOf[currentRoundId][address(this)], sqrt_k_spear[currentRoundId]);
        return spearOut;
    }

    /// @dev sell spear to battle contract, amm satisfies x*y=k. if the price exceeds 0.99, the price will start form last sqrt(k)
    /// @param amount amount of spear to sell
    function sellSpear(uint amount) external {
        uint userSpearAmount = spearBalanceOf[currentRoundId][msg.sender];
        require(userSpearAmount >= amount, "sellSpear::msg.sender has not enough spear to sell");
        uint amountOut = sellSpearOut(amount);
        spearBalanceOf[currentRoundId][msg.sender] = userSpearAmount.sub(amount);
        spearBalanceOf[currentRoundId][address(this)] = spearBalanceOf[currentRoundId][address(this)].add(amount);
        _setPrice();
        collateralToken.safeTransfer(msg.sender, amountOut);
    }

    function shieldSold(uint _roundId) public view returns(uint) {
        return totalShield[_roundId].sub(shieldBalanceOf[_roundId][address(this)]);
    }

    function sellSpearOut(uint amount) public view returns(uint amountOut) {
        // todo
        if (collateralSpear[currentRoundId] >= spearBalanceOf[currentRoundId][address(this)].mul(99).div(100)) {
            amountOut = sellAmount(amount, sqrt_k_spear[currentRoundId], sqrt_k_spear[currentRoundId]);
        } else {
            amountOut = sellAmount(amount, spearBalanceOf[currentRoundId][address(this)], collateralSpear[currentRoundId]);
        }
    }

    /// @dev The price of shield will not exceed 0.99. When the price is less than 0.99, amm satisfies x*y=k, and when the price exceeds 0.99, it satisfies x+y=k.
    /// @param amount the amount of energy token, energy token should a ERC20 token
    function buyShield(uint amount) external {
        collateralToken.safeTransferFrom(msg.sender, address(this), amount);
        (uint shieldOut, bool isBigger, uint pre_k) = getAmountOut(amount, collateralShield[currentRoundId], shieldBalanceOf[currentRoundId][address(this)], sqrt_k_shield[currentRoundId]);
        sqrt_k_shield[currentRoundId] = pre_k;
        collateralShield[currentRoundId] = collateralShield[currentRoundId].add(amount);
        shieldBalanceOf[currentRoundId][address(this)] = shieldBalanceOf[currentRoundId][address(this)].sub(shieldOut);
        shieldBalanceOf[currentRoundId][msg.sender] = shieldBalanceOf[currentRoundId][msg.sender].add(shieldOut);
        if(isBigger) {
            collateralSpear[currentRoundId] = spearBalanceOf[currentRoundId][address(this)].div(100);
        } else {
            collateralSpear[currentRoundId] = shieldBalanceOf[currentRoundId][address(this)].sub(collateralShield[currentRoundId])
            .multiplyDecimal(spearBalanceOf[currentRoundId][address(this)])
            .divideDecimal(shieldBalanceOf[currentRoundId][address(this)]);
        }
        _setPrice();
    }

    function buyShieldOut(uint amount) public view returns(uint) {
        //todo
        (uint shieldOut, bool isBigger, uint pre_k) = getAmountOut(amount, collateralShield[currentRoundId], shieldBalanceOf[currentRoundId][address(this)], sqrt_k_shield[currentRoundId]);
        return shieldOut;
    }

    /// @dev sell spear to battle contract, amm satisfies x*y=k. if the price exceeds 0.99, the price will start form last sqrt(k)
    function sellShield(uint amount) external {
        uint userShieldAmount = shieldBalanceOf[currentRoundId][msg.sender];
        require(userShieldAmount >= amount, "sellShield::msg.sender has not enough shield to sell");
        uint amountOut = sellShieldOut(amount);
        shieldBalanceOf[currentRoundId][msg.sender] = userShieldAmount.sub(amount);
        shieldBalanceOf[currentRoundId][address(this)] = shieldBalanceOf[currentRoundId][address(this)].add(amount);
        _setPrice();
        collateralToken.safeTransfer(msg.sender, amountOut);
    }

    function sellShieldOut(uint amount) public view returns(uint amountOut) {
        //todo
        if (collateralShield[currentRoundId] >= shieldBalanceOf[currentRoundId][address(this)].mul(99).div(100)) {
            amountOut = sellAmount(amount, sqrt_k_shield[currentRoundId], sqrt_k_shield[currentRoundId]);
        } else {
            amountOut = sellAmount(amount, shieldBalanceOf[currentRoundId][address(this)], collateralShield[currentRoundId]);
        }
    }

    /// @dev Announce the results of this round
    /// The final price will be provided by an external third party Oracle
    function settle() external {
        require(block.timestamp >= rounds[currentRoundId].endTS, "too early to settle");
        require(rounds[currentRoundId].roundResult == RoundResult.NonResult, "round had settled");
        uint price = oracle.price(priceName);
        rounds[currentRoundId].endPrice = price;

        uint _range = rounds[currentRoundId].range;
        uint priceUnder = price.multiplyDecimal(uint(1e18).sub(_range));
        uint priceSuper = price.multiplyDecimal(uint(1e18).add(_range));
        rounds[block.timestamp] = RoundInfo({
            spearPrice: rounds[roundIds[0]].spearPrice,
            shieldPrice: rounds[roundIds[0]].shieldPrice,
            // todo
            startPrice: price,
            endPrice: 0,
            startTS: block.timestamp,
            endTS: block.timestamp.add(rounds[currentRoundId].endTS.sub(rounds[currentRoundId].startTS)),
            range: _range,
            ry: rounds[currentRoundId].ry,
            targetPriceUnder: priceUnder,
            targetPriceSuper: priceSuper,
            roundResult: RoundResult.NonResult 
        });
       
        // new round
        uint collateralAmount;
        if (rounds[currentRoundId].ry == RangeType.TwoWay) {
            if (price <= rounds[currentRoundId].targetPriceUnder || price >= rounds[currentRoundId].targetPriceSuper) {
                // spear win
                rounds[currentRoundId].roundResult = RoundResult.SpearWin;
            } else {
                rounds[currentRoundId].roundResult = RoundResult.ShieldWin;
            }
        } else if (rounds[currentRoundId].ry == RangeType.Positive){
            if (price >= rounds[currentRoundId].targetPriceSuper) {
                rounds[currentRoundId].roundResult = RoundResult.SpearWin;
            } else {
                rounds[currentRoundId].roundResult = RoundResult.ShieldWin;
            }
        } else {
            if (price <= rounds[currentRoundId].targetPriceUnder) {
                rounds[currentRoundId].roundResult = RoundResult.SpearWin;
            } else {
                rounds[currentRoundId].roundResult = RoundResult.ShieldWin;
            }
        }
        if(rounds[currentRoundId].roundResult == RoundResult.SpearWin) {
            spearBalanceOf[block.timestamp][address(this)] = spearBalanceOf[currentRoundId][address(this)];
            shieldBalanceOf[block.timestamp][address(this)] = spearBalanceOf[currentRoundId][address(this)];
            collateralAmount = spearBalanceOf[currentRoundId][address(this)];
        } else {
            spearBalanceOf[block.timestamp][address(this)] = shieldBalanceOf[currentRoundId][address(this)];
            shieldBalanceOf[block.timestamp][address(this)] = shieldBalanceOf[currentRoundId][address(this)];
            collateralAmount = shieldBalanceOf[currentRoundId][address(this)];
        }
        spearPrice[block.timestamp] = spearPrice[currentRoundId];
        shieldPrice[block.timestamp] = shieldPrice[currentRoundId];
        collateralSpear[block.timestamp] = spearPrice[block.timestamp].multiplyDecimal(collateralAmount);
        collateralShield[block.timestamp] = shieldPrice[block.timestamp].multiplyDecimal(collateralAmount);
        currentRoundId= block.timestamp;
        roundIds.push(block.timestamp);
    }

    // function needTokenLiqui(uint amount) public view returns(uint _energy0, uint _energy1, uint _reserve0, uint _reserve1) {
    //     _energy0 = energy0.divideDecimal(energy0.add(energy1)).multiplyDecimal(amount);
    //     _energy1 = energy1.divideDecimal(energy0.add(energy1)).multiplyDecimal(amount);
    //     uint per = amount.divideDecimal(energy0.add(energy1));
    //     _reserve0 = per.multiplyDecimal(energy0);
    //     _reserve1 = per.multiplyDecimal(energy1);
    // }

    /// @dev The user adds energy token by calling this function, as well as the corresponding number of spear and shield
    /// @param amount of energy token transfer to battle contract
    function addLiquility(uint amount) external {
        if (userStartRoundLP[msg.sender] < currentRoundId) {
            removeLiquility(0);
        }
        // new
        uint collateralSS = collateralSpear[currentRoundId].add(collateralShield[currentRoundId]);
        uint deltaCollateralSpear = collateralSpear[currentRoundId].multiplyDecimal(amount).divideDecimal(collateralSS);
        uint deltaCollateralShield = collateralShield[currentRoundId].multiplyDecimal(amount).divideDecimal(collateralSS);
        uint deltaSpear = spearBalanceOf[currentRoundId][address(this)].multiplyDecimal(amount).divideDecimal(collateralSS);
        uint deltaShield = shieldBalanceOf[currentRoundId][address(this)].multiplyDecimal(amount).divideDecimal(collateralSS);

        collateralSpear[currentRoundId] = collateralSpear[currentRoundId].add(deltaCollateralSpear);
        collateralShield[currentRoundId] = collateralShield[currentRoundId].add(deltaCollateralShield);
        spearBalanceOf[currentRoundId][address(this)] = spearBalanceOf[currentRoundId][address(this)].add(deltaSpear);
        shieldBalanceOf[currentRoundId][address(this)] = shieldBalanceOf[currentRoundId][address(this)].add(deltaShield);

        totalSpear[currentRoundId] = totalSpear[currentRoundId].add(deltaSpear);
        totalShield[currentRoundId] = totalShield[currentRoundId].add(deltaShield);

        collateralToken.safeTransferFrom(msg.sender, address(this), amount);
        userStartRoundLP[msg.sender] = currentRoundId;
        lpTotalSupply[currentRoundId] = lpTotalSupply[currentRoundId].add(amount);
        lpBalanceOf[currentRoundId][msg.sender] = lpBalanceOf[currentRoundId][msg.sender].add(amount);
    }

    function addLiquilityIn(uint amount) public view returns(uint, uint) {
        uint collateralSS = collateralSpear[currentRoundId].add(collateralShield[currentRoundId]);
        uint deltaSpear = spearBalanceOf[currentRoundId][address(this)].multiplyDecimal(amount).divideDecimal(collateralSS);
        uint deltaShield = shieldBalanceOf[currentRoundId][address(this)].multiplyDecimal(amount).divideDecimal(collateralSS);
        return (deltaSpear, deltaShield);
    }

    function removeLiquilityOut(uint amount) public view returns(uint) {
        uint spearSoldAmount = spearSold(currentRoundId);
        uint shieldSoldAmount = shieldSold(currentRoundId);
        uint maxSold = spearSoldAmount > shieldSoldAmount ? spearSoldAmount : shieldSoldAmount;
        uint deltaCollateral = lpTotalSupply[currentRoundId].sub(maxSold).multiplyDecimal(amount).divideDecimal(lpTotalSupply[currentRoundId]);
        return deltaCollateral;
    }

    /// @dev The user retrieves the energy token
    /// @param amount of energy token to msg.sender, if msg.sender don't have enought spear and shield, the transaction
    /// will failed
    function removeLiquility(uint amount) public  {
        // require(userStartRoundLP[msg.sender] !=0, "user dont have liquility");
        if(userStartRoundLP[msg.sender] == 0) {
            return;
        }
        uint lpAmount;
        if (userStartRoundLP[msg.sender] == currentRoundId) {
            // dont have history
            lpAmount = lpBalanceOf[currentRoundId][msg.sender];
        } else {
            // history handle
            lpAmount = pendingLP(msg.sender);
        }
        require(lpAmount >= amount, "not enough lp to burn");
        uint spearSoldAmount = spearSold(currentRoundId);
        uint shieldSoldAmount = shieldSold(currentRoundId);
        uint maxSold = spearSoldAmount > shieldSoldAmount ? spearSoldAmount : shieldSoldAmount;
        uint deltaCollateral = lpTotalSupply[currentRoundId].sub(maxSold).multiplyDecimal(amount).divideDecimal(lpTotalSupply[currentRoundId]);
        uint deltaSpear = deltaCollateral.multiplyDecimal(collateralSpear[currentRoundId]).divideDecimal(lpTotalSupply[currentRoundId]);
        uint deltaShield = deltaCollateral.multiplyDecimal(collateralShield[currentRoundId]).divideDecimal(lpTotalSupply[currentRoundId]);
        uint deltaCollateralSpear = collateralSpear[currentRoundId].multiplyDecimal(deltaCollateral).divideDecimal(lpTotalSupply[currentRoundId]);
        uint deltaCollateralShield = collateralShield[currentRoundId].multiplyDecimal(deltaCollateral).divideDecimal(lpTotalSupply[currentRoundId]);
        uint deltaCollateralSurplus = collateralSurplus[currentRoundId].multiplyDecimal(deltaCollateral).divideDecimal(lpTotalSupply[currentRoundId]);

        spearBalanceOf[currentRoundId][address(this)] = spearBalanceOf[currentRoundId][address(this)].sub(deltaSpear);
        shieldBalanceOf[currentRoundId][address(this)] = shieldBalanceOf[currentRoundId][address(this)].sub(deltaShield);
        collateralSpear[currentRoundId] = collateralSpear[currentRoundId].sub(deltaCollateralSpear);
        collateralShield[currentRoundId] = collateralShield[currentRoundId].sub(deltaCollateralShield);
        collateralSurplus[currentRoundId] = collateralSurplus[currentRoundId].sub(deltaCollateralSurplus);

        totalSpear[currentRoundId] = totalSpear[currentRoundId].sub(deltaSpear);
        totalShield[currentRoundId] = totalShield[currentRoundId].sub(deltaShield);

        userStartRoundLP[msg.sender] = currentRoundId;
        lpTotalSupply[currentRoundId] = lpTotalSupply[currentRoundId].sub(amount);
        lpBalanceOf[currentRoundId][msg.sender] = lpAmount.sub(amount);
        collateralToken.safeTransfer(msg.sender, deltaCollateral);
        
    }

    function pendingClaim(address acc) public view returns(uint amount) {
        uint userRoundId = userStartRoundSS[acc];
        if(userRoundId != 0 && userRoundId < currentRoundId) {
            if(rounds[userRoundId].roundResult == RoundResult.SpearWin) {
                amount = spearBalanceOf[userRoundId][acc];
            } else if (rounds[userRoundId].roundResult == RoundResult.ShieldWin) {
                amount = shieldBalanceOf[userRoundId][acc];
            }
        }
    }

    function pendingLP(address acc) public view returns(uint lpAmount) {
        uint userRoundId = userStartRoundLP[acc];
        if(userRoundId != 0 && userRoundId <= currentRoundId) {
                // future round
                lpAmount = lpBalanceOf[userRoundId][acc];
                for(uint i; i < roundIds.length-1;i++) {
                    if (roundIds[i] >= userRoundId) {
                        // user's all round
                        uint newLpAmount = nextRoundLP(roundIds[i], acc, lpAmount);
                        lpAmount = newLpAmount;
                    }
                }
        }
    }

    function nextRoundLP(uint roundId, address acc, uint lpAmount) public view returns(uint amount) {
        if(roundId == currentRoundId) {
            return lpBalanceOf[roundId][acc];
        }
        if(rounds[roundId].roundResult == RoundResult.SpearWin) {
            uint spearAmountTotal = spearBalanceOf[roundId][address(this)];
            amount = lpAmount.multiplyDecimal(spearAmountTotal).divideDecimal(lpTotalSupply[roundId]);
        } else {
            uint shieldAmountTotal = shieldBalanceOf[roundId][address(this)];
            amount = lpAmount.multiplyDecimal(shieldAmountTotal).divideDecimal(lpTotalSupply[roundId]);
        }
    }

    /// @dev normal users get back their profits
    function claim() public {
        uint amount = pendingClaim(msg.sender);
        if (amount != 0) {
            spearBalanceOf[userStartRoundSS[msg.sender]][msg.sender] = 0;
            shieldBalanceOf[userStartRoundSS[msg.sender]][msg.sender] = 0;
            delete userStartRoundSS[msg.sender];
            collateralToken.safeTransfer(msg.sender, amount);
        }
    }

    /// @dev Calculate how many spears and shields can be obtained
    /// @param amountIn amount transfer to battle contract
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint _pre_k) public pure returns (uint amountOut, bool e, uint pre_k) {
        require(amountIn > 0, 'Battle: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'Battle: INSUFFICIENT_LIQUIDITY');
        if (reserveIn >= reserveOut.mul(99).div(100)) {
            amountOut = amountIn;
            e = true;
            return (amountOut, e, _pre_k);
        }
        // if amountIn > sqrt(reserveIn)
        uint maxAmount = DMath.sqrt(reserveIn*reserveOut.mul(100).div(99));
        pre_k = maxAmount;
        // console.log("maxAmount %s and amountIn %s, reserveIn %s, reserveOut %s", maxAmount, amountIn, reserveIn);
        if (amountIn.add(reserveIn) > maxAmount) {
            uint maxAmountIn = maxAmount.sub(reserveIn);
            uint amountInWithFee = maxAmountIn.mul(1000);
            uint numerator = amountInWithFee.mul(reserveOut);
            uint denominator = reserveIn.mul(1000).add(amountInWithFee);
            amountOut = numerator / denominator;
            amountOut = amountOut.add(amountIn.sub(maxAmountIn));
            e = true;
        } else {
            uint amountInWithFee = amountIn.mul(1000);
            uint numerator = amountInWithFee.mul(reserveOut);
            uint denominator = reserveIn.mul(1000).add(amountInWithFee);
            amountOut = numerator / denominator;
        }
    }

    function sellAmount(uint amountToSell, uint reserve, uint energy) public pure returns(uint amount) {
        uint amountInWithFee = amountToSell.mul(1000);
        uint numerator = amountInWithFee.mul(energy);
        uint denominator = reserve.mul(1000).add(amountInWithFee);
        amount = numerator / denominator;
    }

    function test() public {}

    // // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    // function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public pure returns (uint amountIn) {
    //     require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
    //     require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
    //     uint numerator = reserveIn.multiplyDecimal(amountOut).mul(1000);
    //     uint denominator = reserveOut.sub(amountOut).mul(1000);
    //     amountIn = (numerator / denominator).add(1);
    // }
}
