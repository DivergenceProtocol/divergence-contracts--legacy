// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "../structs/SettleType.sol";
import "../lib/SafeDecimalMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Oracle is Initializable, UUPSUpgradeable, OwnableUpgradeable{
    using SafeDecimalMath for uint;

    mapping(string=>uint) public price;
    mapping(string=>mapping(uint=>uint)) public historyPrice;
    // bytes32 public ORACLE_ROLE;

    uint[] public monSTS;
    // uint[] public monETS;

    function initialize() public initializer {
        // _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // _setupRole(ORACLE_ROLE, msg.sender);
        // ORACLE_ROLE = "oracle_role";
        __Ownable_init_unchained();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setPrice(string memory symbol, uint ts, uint _price) public onlyOwner{
        // require(hasRole(ORACLE_ROLE, msg.sender), "caller not oracle");
        price[symbol] = _price;
        historyPrice[symbol][ts] = _price;
    }

    function setMultiPrice(string memory symbol, uint[] memory ts, uint[] memory _prices) public {
        require(ts.length == _prices.length, "length should match");
        for(uint i; i < ts.length; i++) {
            setPrice(symbol, ts[i], _prices[i]);
        }
    }

    // function setMonthTS(uint256[] memory starts, uint256[] memory ends) public {
    //     require(starts.length == ends.length, "starts and ends should match");
    //     for (uint256 i; i < starts.length; i++) {
    //         monSTS.push(starts[i]);
    //         monETS.push(ends[i]);
    //     }
    // }

    function setMonthTS(uint256[] memory starts) public {
        for (uint256 i; i < starts.length; i++) {
            monSTS.push(starts[i]);
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
        uint _peroidType,
        uint _settleType,
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
        (uint256 startTS, ) = getRoundTS(_peroidType);
        startPrice = historyPrice[symbol][startTS];
        uint256 settlePrice;
        uint256 settlePriceOver;
        uint256 settlePriceUnder;
        if (_settleType == 3) {
            settlePrice = _settleValue;
        } else if (_settleType == 0) {
            settlePriceOver = startPrice.multiplyDecimal(1e18 + _settleValue);
            settlePriceUnder = startPrice.multiplyDecimal(1e18 - _settleValue);
        } else if (_settleType == 1) {
            settlePriceOver = startPrice.multiplyDecimal(1e18 + _settleValue);
        } else if (_settleType == 2) {
            settlePriceUnder = startPrice.multiplyDecimal(1e18 - _settleValue);
        } else {
            revert("unknown Settle Type");
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

    function getTS(uint _peroidType, uint offset) public view returns(uint start, uint end) {
        // 0 => day
        if (_peroidType == 0) {
            start = block.timestamp - (block.timestamp % 86400);
            end = start + 86400*(1+offset);
        } else if (_peroidType == 1) {
            // 1 => week
            start = block.timestamp - ((block.timestamp + 259200) % 604800);
            end = start + 604800*(1+offset);
        } else if (_peroidType == 2) {
            // 2 => month
            for (uint256 i; i < monSTS.length; i++) {
                if (
                    block.timestamp >= monSTS[i] && block.timestamp <= monSTS[i+1]
                ) {
                    uint index = i+offset;
                    start = monSTS[index];
                    end = monSTS[index+1];
                }
            }
            require(start != 0, "not known start ts");
            require(end != 0, "not known end ts");
        }
    }

    function getRoundTS(uint _peroidType) public view returns(uint start, uint end) {
        return getTS(_peroidType, 0);
    }

    function getNextRoundTS(uint _peroidType) public view returns(uint start, uint end) {
        return getTS(_peroidType, 1);
    }

}