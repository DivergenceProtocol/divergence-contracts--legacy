// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./Battle.sol";
import "./structs/SettleType.sol";
import "./structs/PeroidType.sol";
import "./structs/TS.sol";
import "./interfaces/IArena.sol";
import "./interfaces/IOracle.sol";
import "./lib/SafeDecimalMath.sol";


pragma solidity ^0.8.0;

contract Arena is IArena {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeDecimalMath for uint;

    EnumerableSetUpgradeable.AddressSet private battleSet;

    TS[] public monthTS;

    IOracle public oracle;

    mapping(address => bool) public isExist;

    function setMonthTS(uint256[] memory starts, uint256[] memory ends) public {
        require(starts.length == ends.length, "starts and ends should match");
        for (uint256 i; i < starts.length; i++) {
            monthTS.push(TS({start: starts[i], end: ends[i]}));
        }
    }

    function battleLength() public view returns (uint256 len) {
        len = battleSet.length();
    }

    function addBattle(address _battle) public {
        battleSet.add(_battle);
    }

    function getBattle(uint256 index) public view returns (address _battle) {
        _battle = battleSet.at(index);
    }

    function removeBattle(address _battle) public {
        battleSet.remove(_battle);
    }

    function containBattle(address _battle) public view returns (bool) {
        return battleSet.contains(_battle);
    }

    // /**
    //  * @param _collateral collateral token address, eg. DAI
    //  * @param _oracle oracle contract address
    //  * @param _trackName battle's track name, eg. WBTC-DAI
    //  * @param _priceName eg. BTC
    //  * @param amount collateral's amount
    //  * @param _spearPrice init price of spear, eg. 0.5*10**18
    //  * @param _shieldPrice init price of shield, eg. 0.5*10**18
    //  */
    function createBattle(
        address _collateral,
        IOracle _oracle,
        string memory _trackName,
        string memory _priceName,
        uint256 _cAmount,
        uint256 _spearPrice,
        uint256 _shieldPrice,
        PeroidType _peroidType,
        SettleType _settleType,
        uint256 _settleValue
    ) public {
        // require(_peroidType == 0 || _peroidType == 1 || _peroidType == 2, "Not support battle duration");
        require(
            _spearPrice + _shieldPrice == 1e18,
            "Battle::init:spear + shield should 1"
        );
        IERC20Upgradeable(_collateral).safeTransferFrom(
            msg.sender,
            address(this),
            _cAmount
        );
        bytes32 salt =
            keccak256(
                abi.encodePacked(
                    _collateral,
                    _trackName,
                    _peroidType,
                    _settleType,
                    _settleValue
                )
            );
        bytes32 bytecodeHash = keccak256(type(Battle).creationCode);
        address battleAddr =
            Create2Upgradeable.computeAddress(salt, bytecodeHash);
        require(
            battleSet.contains(battleAddr) == false,
            "battle already exist"
        );
        Create2Upgradeable.deploy(0, salt, type(Battle).creationCode);
        IERC20Upgradeable(_collateral).safeTransfer(battleAddr, _cAmount);
        Battle battle = Battle(battleAddr);
        battle.init0(
            _collateral,
            address(this),
            _trackName,
            _priceName,
            _peroidType,
            _settleType,
            _settleValue
        );
        battle.init(msg.sender, _cAmount, _spearPrice, _shieldPrice);
        battleSet.add(address(battle));
    }

    function getPeroidTS(PeroidType _peroidType)
        public
        view
        override
        returns (uint256 start, uint256 end)
    {
        // 0 => day
        if (_peroidType == PeroidType.Day) {
            start = block.timestamp - (block.timestamp % 86400);
            end = start + 86400;
        } else if (_peroidType == PeroidType.Week) {
            // 1 => week
            start = block.timestamp - ((block.timestamp + 259200) % 604800);
            end = start + 604800;
        } else if (_peroidType == PeroidType.Month) {
            // 2 => month
            for (uint256 i; i < monthTS.length; i++) {
                if (
                    monthTS[i].start >= block.timestamp &&
                    monthTS[i].end <= block.timestamp
                ) {
                    start = monthTS[i].start;
                    end = monthTS[i].end;
                }
            }
            require(start != 0, "not known start ts");
            require(end != 0, "not known end ts");
        }
    }

    function getSpacePrice(uint256 oraclePrice, uint256 rawPrice)
        public
        pure
        override
        returns (uint256 price)
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
            price = (rawPrice / unit0) * unit0;
        } else {
            price = (rawPrice / unit1) * unit1;
        }
    }

    function getStrikePrice(string memory symbol, PeroidType _peroidType, SettleType _settleType, uint _settleValue)
        public
        override
        view
        returns (
            uint256 startPrice,
            uint256 strikePrice,
            uint256 strikePriceOver,
            uint256 strikePriceUnder
        )
    {
        (uint startTS, uint endTS) = getPeroidTS(_peroidType);
        uint startPrice = oracle.historyPrice(symbol, startTS);
        uint settlePrice;
        uint settlePriceOver;
        uint settlePriceUnder;
        if (_settleType == SettleType.Specific) {
            settlePrice = _settleValue;
        } else if (_settleType == SettleType.TwoWay) {
            settlePriceOver = startPrice.multiplyDecimal(1e18+_settleValue);
            settlePriceUnder = startPrice.multiplyDecimal(1e18-_settleValue);
        } else if (_settleType == SettleType.Positive) {
            settlePriceOver = startPrice.multiplyDecimal(1e18+_settleValue);
        } else if (_settleType == SettleType.Negative) {
            settlePriceUnder = startPrice.multiplyDecimal(1e18-_settleValue);
        } else {
            revert("unknown Settle Type");
        }
        strikePrice = getSpacePrice(startPrice, settlePrice);
        strikePriceOver = getSpacePrice(startPrice, settlePriceOver);
        strikePriceUnder = getSpacePrice(startPrice, settlePriceUnder);
    }

    function getPriceByTS(string memory symbol, uint ts) public override view returns(uint) {
        return oracle.historyPrice(symbol, ts);
    }
}
