// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
// import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import '../structs/SettleType.sol';
import '../lib/SafeDecimalMath.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '../interfaces/AggregatorV3Interface.sol';
import '../structs/SettleType.sol';
import '../structs/PeroidType.sol';

contract Oracle is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeDecimalMath for uint256;

    mapping(string => uint256) public price;
    mapping(string => mapping(uint256 => uint256)) public historyPrice;
    // bytes32 public ORACLE_ROLE;

    uint256[] public monSTS;
    // uint[] public monETS;
    mapping(string => AggregatorV3Interface) public externalOracles;

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function setExternalOracle(
        string[] memory symbols,
        address[] memory _oracles
    ) public onlyOwner {
        require(symbols.length == _oracles.length, 'symbols not match oracles');
        for (uint256 i = 0; i < symbols.length; i++) {
            externalOracles[symbols[i]] = AggregatorV3Interface(_oracles[i]);
        }
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setPrice(
        string memory symbol,
        uint256 ts,
        uint256 _price
    ) public onlyOwner {
        // require(hasRole(ORACLE_ROLE, msg.sender), "caller not oracle");
        price[symbol] = _price;
        historyPrice[symbol][ts] = _price;
    }

    function setMultiPrice(
        string memory symbol,
        uint256[] memory ts,
        uint256[] memory _prices
    ) public {
        require(ts.length == _prices.length, 'length should match');
        for (uint256 i; i < ts.length; i++) {
            setPrice(symbol, ts[i], _prices[i]);
        }
    }

    function setMonthTS(uint256[] memory starts) public onlyOwner {
        for (uint256 i; i < starts.length; i++) {
            monSTS.push(starts[i]);
        }
    }

    function deleteMonthTS() public onlyOwner {
        for (uint256 i; i < monSTS.length; i++) {
            monSTS.pop();
        }
    }

    // peroidType:
    // settleType:
    // TwoWay, // 0
    // Positive, // 1
    // Negative, // 2
    // Specific // 3
    function getStrikePrice(
        string memory symbol,
        PeroidType _pt,
        SettleType _st,
        uint256 _settleValue
    )
        public
        view
        returns (
            uint256 startPrice,
            uint256 strikePrice,
            uint256 strikePriceOver,
            uint256 strikePriceUnder
        )
    {
        (uint256 startTS, ) = getRoundTS(_pt);
        startPrice = historyPrice[symbol][startTS];
        uint256 settlePrice;
        uint256 settlePriceOver;
        uint256 settlePriceUnder;
        if (_st == SettleType.Specific) {
            settlePrice = _settleValue;
        } else if (_st == SettleType.TwoWay) {
            settlePriceOver = startPrice.multiplyDecimal(1e18 + _settleValue);
            settlePriceUnder = startPrice.multiplyDecimal(1e18 - _settleValue);
        } else if (_st == SettleType.Positive) {
            settlePriceOver = startPrice.multiplyDecimal(1e18 + _settleValue);
        } else if (_st == SettleType.Negative) {
            settlePriceUnder = startPrice.multiplyDecimal(1e18 - _settleValue);
        } else {
            revert('unknown Settle Type');
        }
        strikePrice = getSpacePrice(startPrice, settlePrice);
        strikePriceOver = getSpacePrice(startPrice, settlePriceOver);
        strikePriceUnder = getSpacePrice(startPrice, settlePriceUnder);
    }

    function getSpacePrice(uint256 oraclePrice, uint256 rawPrice)
        public
        pure
        returns (uint256 price_)
    {
        uint256 i = 12;
        while (oraclePrice / 10**i >= 10) {
            i += 1;
        }
        uint256 minI = i - 2;
        uint256 maxI = i - 1;
        uint256 unit0 = 10**minI;
        uint256 unit1 = 10**maxI;

        uint256 overBound = (oraclePrice * 130) / 100;
        uint256 underBound = (oraclePrice * 70) / 100;
        if (rawPrice >= underBound || rawPrice <= overBound) {
            price_ = (rawPrice / unit0) * unit0;
        } else {
            price_ = (rawPrice / unit1) * unit1;
        }
    }

    function getTS(PeroidType _peroidType, uint256 offset)
        public
        view
        returns (uint256 start, uint256 end)
    {
        // 0 => day
        if (_peroidType == PeroidType.Day) {
            // start = block.timestamp - ((block.timestamp-36000) % 86400);
            // start = start + 86400*offset;
            // end = start + 86400;

            start = block.timestamp - ((block.timestamp - 28800) % 86400);
            start = start + 86400 * offset;
            end = start + 86400;
        } else if (_peroidType == PeroidType.Week) {
            // 1 => week
            start = block.timestamp - ((block.timestamp - 115200) % 604800);
            start = start + 604800 * offset;
            end = start + 604800;
        } else if (_peroidType == PeroidType.Month) {
            // 2 => month
            for (uint256 i; i < monSTS.length; i++) {
                if (
                    block.timestamp >= monSTS[i] &&
                    block.timestamp <= monSTS[i + 1]
                ) {
                    uint256 index = i + offset;
                    start = monSTS[index];
                    end = monSTS[index + 1];
                }
            }
            require(start != 0, 'not known start ts');
            require(end != 0, 'not known end ts');
        }
    }

    function getRoundTS(PeroidType _peroidType)
        public
        view
        returns (uint256 start, uint256 end)
    {
        return getTS(_peroidType, 0);
    }

    function getNextRoundTS(PeroidType _pt)
        public
        view
        returns (uint256 start, uint256 end)
    {
        return getTS(_pt, 1);
    }

    function getPriceByExternal(string memory symbol, uint256 ts)
        public
        view
        returns (uint256)
    {
        require(
            address(externalOracles[symbol]) != address(0),
            'external oracle exist'
        );
        uint256 price_;
        uint80 roundID;
        int256 answer;
        uint256 updateAt;
        (roundID, answer, , updateAt, ) = externalOracles[symbol]
            .latestRoundData();
        uint80 maxRoundID = roundID;
        for (uint80 i = maxRoundID; i > 0; i--) {
            (, int256 preAnswer, , uint256 preUpdateAt, ) = externalOracles[
                symbol
            ].getRoundData(i - 1);
            if (updateAt < ts) {
                break;
            }
            if (updateAt - ts < 600 && preUpdateAt < ts) {
                price_ =
                    10**(18 - externalOracles[symbol].decimals()) *
                    uint256(answer);
                break;
            } else {
                answer = preAnswer;
                updateAt = preUpdateAt;
            }
        }
        require(price_ != 0, 'Price not found for ts');
        return price_;
    }

    function updatePriceByExternal(string memory symbol, uint256 ts)
        public
        returns (uint256 price_)
    {
        if (historyPrice[symbol][ts] != 0) {
            price_ = historyPrice[symbol][ts];
        } else {
            price_ = getPriceByExternal(symbol, ts);
            historyPrice[symbol][ts] = price_;
        }
    }
}
