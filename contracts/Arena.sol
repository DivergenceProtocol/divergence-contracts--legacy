// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./structs/InitParams.sol";
import "./interfaces/IOracle.sol";
import "./lib/SafeDecimalMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBattle.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

pragma solidity ^0.8.0;

contract Arena is Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeDecimalMath for uint256;

    EnumerableSet.AddressSet private battleSet;

    IOracle public oracle;
    mapping(address => bool) public isExist;
    mapping(string => bool) public underlyingList;
    mapping(address => bool) public supportedCollateral;
    mapping(bytes32 => bool) public paramsExist;
    bool public isOpen;
    mapping(address => bool) public isBattleCreater;

    address public impl;

    address public feeTo;

    uint256 twoWayLimit = 9e17;
    uint256 positiveLimit = 1e18;
    uint256 negativeLimit = 9e17;
    uint256 specificUnderLimit = 1e17;
    uint256 specificOverLimit = 2e18;

    // ==========event=============
    event BattleCreated(address battle, address collateral, string underlying, uint256 periodType, uint256 settleType, uint256 strikeValue, uint256 battleLength);
    event FeeToChanged(address battle, address feeTo);
    event FeeRatioChanged(address battle, uint256 ratio);
    event SupportedCollateralChanged(address collateral, bool state);
    event BattleCreaterChanged(address creater, bool state);

    constructor(
        address _impl,
        address _oracle,
        address _feeTo
    ) {
        require(_impl != address(0), "zero address");
        require(_oracle != address(0), "zero address");
        impl = _impl;
        oracle = IOracle(_oracle);
        feeTo = _feeTo;
    }

    function setImpl(address _impl) external onlyOwner {
        require(_impl != address(0), "zero address");
        impl = _impl;
    }

    function setUnderlying(string memory underlying, bool isSupport) external onlyOwner {
        underlyingList[underlying] = isSupport;
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = IOracle(_oracle);
    }

    function battleLength() public view returns (uint256 len) {
        len = battleSet.length();
    }

    function getBattle(uint256 index) external view returns (address _battle) {
        _battle = battleSet.at(index);
    }

    function containBattle(address _battle) external view returns (bool) {
        return battleSet.contains(_battle);
    }

    function removeBattle(address _battle) external onlyOwner {
        battleSet.remove(_battle);
    }

    function setSupportedCollateral(address _collateral, bool state) public onlyOwner {
        require(supportedCollateral[_collateral] != state);
        supportedCollateral[_collateral] = state;
        emit SupportedCollateralChanged(_collateral, state);
    }

    function setMultiSupportedCollateral(address[] memory _collaterals, bool[] memory states) external {
        require(_collaterals.length == states.length, "length not match");
        for (uint256 i = 0; i < _collaterals.length; i++) {
            setSupportedCollateral(_collaterals[i], states[i]);
        }
    }

    function setIsOpen(bool _isOpen) external onlyOwner {
        isOpen = _isOpen;
    }

    function setBattleCreater(address _creater, bool state) public onlyOwner {
        require(isBattleCreater[_creater] != state);
        isBattleCreater[_creater] = state;
        emit BattleCreaterChanged(_creater, state);
    }

    function setMutiBattleCreater(address[] memory _creaters, bool[] memory states) external {
        require(_creaters.length == states.length, "length not match");
        for (uint256 i = 0; i < _creaters.length; i++) {
            setBattleCreater(_creaters[i], states[i]);
        }
    }

    function setTwowayLimit(uint256 value) external onlyOwner {
        require(value != 0, "limit value error");
        twoWayLimit = value;
    }

    function setPositiveLimit(uint256 value) external onlyOwner {
        require(value != 0, "limit value error");
        positiveLimit = value;
    }

    function setNegativeLimit(uint256 value) external onlyOwner {
        require(value != 0, "limit value error");
        negativeLimit = value;
    }

    function setSpecificUnderLimit(uint256 value) external onlyOwner {
        require(value != 0, "limit value error");
        specificUnderLimit = value;
    }

    function setSpecificOverLimit(uint256 value) external onlyOwner {
        require(value != 0, "limit value error");
        specificOverLimit = value;
    }


    function tryCreateBattle(
        address _collateral,
        string memory _underlying,
        PeriodType _periodType,
        SettleType _settleType,
        uint256 _strikeValue
    ) public view returns (bool, bytes32) {
        bytes32 paramsHash = keccak256(abi.encodePacked(_collateral, _underlying, _periodType, _settleType, _strikeValue));
        return (paramsExist[paramsHash], paramsHash);
    }

    /**
     * @param _collateral collateral token address, eg. DAI
     * @param _cAmount collateral's amount
     * @param _spearPrice init price of spear, eg. 0.5*10**18
     * @param _shieldPrice init price of shield, eg. 0.5*10**18
     */
    function createBattle(
        address _collateral,
        string memory _underlying,
        uint256 _cAmount,
        uint256 _spearPrice,
        uint256 _shieldPrice,
        PeriodType _periodType,
        SettleType _settleType,
        uint256 _strikeValue
    ) external {
        if (!isOpen) {
            require(isBattleCreater[msg.sender] == true, "user cant create Battle");
        }
        require(supportedCollateral[_collateral] == true, "not support collateral");
        require(underlyingList[_underlying], "not support underlying");
        require(_cAmount > 0, "cAmount 0");
        require(_spearPrice + _shieldPrice == 1e18, "should 1");

        if (_settleType != SettleType.Specific) {
            require(_strikeValue > 0, "settle value error");
            require(_strikeValue % 1e16 == 0, "Arena::min 1%");
        }

        if (_settleType == SettleType.TwoWay) {
            require(_strikeValue <= twoWayLimit, "settle value error");
        } else if (_settleType == SettleType.Positive) {
            require(_strikeValue <= positiveLimit, "settle value error");
        } else if (_settleType == SettleType.Negative) {
            require(_strikeValue <= negativeLimit, "settle value error");
        } else {
            (uint256 start, ) = oracle.getRoundTS(_periodType);
            uint256 prePrice = oracle.historyPrice(_underlying, start);
            require(prePrice > 0, "price not exist");
            require(_strikeValue >= prePrice.multiplyDecimal(specificUnderLimit) && _strikeValue <= prePrice.multiplyDecimal(specificOverLimit), "settle value error");
        }

        (bool exist, bytes32 paramsHash) = tryCreateBattle(_collateral, _underlying, _periodType, _settleType, _strikeValue);
        require(!exist, "params exist");
        paramsExist[paramsHash] = true;
        address battleAddr = Clones.clone(impl);
        battleSet.add(battleAddr);
        IERC20(_collateral).safeTransferFrom(msg.sender, battleAddr, _cAmount);
        InitParams memory p;
        p._collateral = _collateral;
        p._underlying = _underlying;
        p._cAmount = _cAmount;
        p._spearPrice = _spearPrice;
        p._shieldPrice = _shieldPrice;
        p._periodType = _periodType;
        p._settleType = _settleType;
        p._strikeValue = _strikeValue;
        p.battleCreater = msg.sender;
        p._oracle = address(oracle);
        p._feeTo = feeTo;
        IBattle(battleAddr).init(p);
        emit BattleCreated(battleAddr, _collateral, _underlying, uint256(_periodType), uint256(_settleType), uint256(_strikeValue), battleSet.length());
    }

    function setBattleFeeTo(address battle, address _feeTo) external onlyOwner {
        IBattle(battle).setFeeTo(_feeTo);
        emit FeeToChanged(battle, _feeTo);
    }

    function setBattleFeeRatio(address battle, uint256 feeRatio) external onlyOwner {
        require(feeRatio < 1e18, "feeRatio error");
        IBattle(battle).setFeeRatio(feeRatio);
        emit FeeRatioChanged(battle, feeRatio);
    }

    // function setSettleReward(address battle, uint256 amount) external onlyOwner {
    //     IBattle(battle).setSettleReward(amount);
    // }
}
