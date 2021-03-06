// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "../structs/SettleType.sol";
import "../lib/SafeDecimalMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/AggregatorV3Interface.sol";
import "../structs/SettleType.sol";
import "../structs/PeriodType.sol";

contract Oracle is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeDecimalMath for uint256;

    mapping(string => uint256) public price;
    mapping(string => mapping(uint256 => uint256)) public historyPrice;

    uint256[] public monSTS;
    mapping(string => AggregatorV3Interface) public externalOracles;

    // uint256 public tolerance = 60;

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function setExternalOracle(string[] memory symbols, address[] memory _oracles) external onlyOwner {
        require(symbols.length == _oracles.length, "symbols not match oracles");
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
        price[symbol] = _price;
        historyPrice[symbol][ts] = _price;
    }

    function setMultiPrice(
        string memory symbol,
        uint256[] memory ts,
        uint256[] memory _prices
    ) external {
        require(ts.length == _prices.length, "length should match");
        for (uint256 i; i < ts.length; i++) {
            setPrice(symbol, ts[i], _prices[i]);
        }
    }

    function setMonthTS(uint256[] memory starts) external onlyOwner {
        for (uint256 i; i < starts.length; i++) {
            monSTS.push(starts[i]);
        }
    }

    function deleteMonthTS() external onlyOwner {
        for (uint256 i; i < monSTS.length; i++) {
            monSTS.pop();
        }
    }

    // periodType:
    // settleType:
    // TwoWay, // 0
    // Positive, // 1
    // Negative, // 2
    // Specific // 3
    function getStrikePrice(
        string memory symbol,
        PeriodType _pt,
        SettleType _st,
        uint256 _strikeValue
    )
        external
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
            settlePrice = _strikeValue;
        } else if (_st == SettleType.TwoWay) {
            settlePriceOver = startPrice.multiplyDecimal(1e18 + _strikeValue);
            settlePriceUnder = startPrice.multiplyDecimal(1e18 - _strikeValue);
        } else if (_st == SettleType.Positive) {
            settlePriceOver = startPrice.multiplyDecimal(1e18 + _strikeValue);
        } else if (_st == SettleType.Negative) {
            settlePriceUnder = startPrice.multiplyDecimal(1e18 - _strikeValue);
        } else {
            revert("unknown Settle Type");
        }
        strikePrice = getSpacePrice(settlePrice, _st);
        strikePriceOver = getSpacePrice(settlePriceOver, _st);
        strikePriceUnder = getSpacePrice(settlePriceUnder, _st);
    }

    function getSpacePrice(uint256 _price, SettleType _st) public pure returns (uint256 price_) {
        uint256 i = 12;
        while (_price / 10**i >= 10) {
            i += 1;
        }
        uint256 minI = i - 2;
        uint256 maxI = i - 1;
        uint256 unit0 = 10**minI;
        uint256 unit1 = 10**maxI;

        if (_st == SettleType.Specific) {
            price_ = (_price / unit1) * unit1;
        } else {
            price_ = (_price / unit0) * unit0;
        }
    }

    function getTS(PeriodType _periodType, uint256 offset) public view returns (uint256 start, uint256 end) {
        // 0 => day
        if (_periodType == PeriodType.Day) {
            start = block.timestamp - ((block.timestamp - 28800 - 5*3600 - 900) % 86400);
            start = start + 86400 * offset;
            end = start + 86400;
        } else if (_periodType == PeriodType.Week) {
            // 1 => week
            start = block.timestamp - ((block.timestamp - 115200) % 604800);
            start = start + 604800 * offset;
            end = start + 604800;
        } else if (_periodType == PeriodType.Month) {
            // 2 => month
            for (uint256 i; i < monSTS.length; i++) {
                if (block.timestamp >= monSTS[i] && block.timestamp <= monSTS[i + 1]) {
                    uint256 index = i + offset;
                    start = monSTS[index];
                    end = monSTS[index + 1];
                }
            }
            require(start != 0, "not known start ts");
            require(end != 0, "not known end ts");
        }
    }

    function getRoundTS(PeriodType _periodType) public view returns (uint256 start, uint256 end) {
        return getTS(_periodType, 0);
    }

    function getNextRoundTS(PeriodType _pt) external view returns (uint256 start, uint256 end) {
        return getTS(_pt, 1);
    }

    function getPriceByExternal(string memory symbol, uint256 ts) public view returns (uint256) {
        AggregatorV3Interface cOracle = externalOracles[symbol];
        require(address(cOracle) != address(0), "external oracle not exist");

        (uint80 roundID, , , , ) = cOracle.latestRoundData();

        uint256 minTS = ts - 1800;
        uint256 mediumTS = ts - 900;
        uint256 decimalDiff = 10**(18 - cOracle.decimals());
        (uint256 firstPrice, uint80 firstId) = _getPrice(cOracle, roundID, ts, decimalDiff);
        (uint256 secondPrice, uint80 secondId) = _getPrice(cOracle, firstId, mediumTS, decimalDiff);
        (uint256 thirdPrice, ) = _getPrice(cOracle, secondId, minTS, decimalDiff);
        return (firstPrice + secondPrice + thirdPrice) / 3;
    }

    function _getPrice(
        AggregatorV3Interface cOracle,
        uint80 id,
        uint256 ts,
        uint256 decimalDiff
    ) internal view returns (uint256 p, uint80 i) {
        for (i = id; i > 0; i--) {
            (, int256 answer, uint256 startedAt, , ) = cOracle.getRoundData(i);
            if (startedAt < ts) {
                break;
            }
            if ((startedAt - ts) <= 60) {
                p = decimalDiff * uint256(answer);
            }
        }
        require(p != 0, "price not exist");
    }

    function updatePriceByExternal(string memory symbol, uint256 ts) external returns (uint256 price_) {
        if (historyPrice[symbol][ts] != 0) {
            price_ = historyPrice[symbol][ts];
        } else {
            price_ = getPriceByExternal(symbol, ts);
            historyPrice[symbol][ts] = price_;
        }
    }
}
