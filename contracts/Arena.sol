// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import './structs/SettleType.sol';
import './structs/PeroidType.sol';
import './interfaces/IOracle.sol';
import './lib/SafeDecimalMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IBattle.sol';
import '@openzeppelin/contracts/proxy/Clones.sol';

pragma solidity ^0.8.0;

contract Arena is Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeDecimalMath for uint256;

    EnumerableSet.AddressSet private battleSet;

    IOracle public oracle;

    mapping(address => bool) public isExist;

    mapping(string => bool) public underlyingList;

    mapping(bytes32 => bool) public paramsExist;

    address public impl;

    // ==========event=============
    event BattleCreated(
        address battle,
        address collateral,
        string underlying,
        uint256 peroidType,
        uint256 settleType,
        uint256 settleValue,
        uint256 battleLength
    );
    event FeeToChanged(address battle, address feeTo);
    event FeeRatioChanged(address battle, uint256 ratio);

    constructor(address _impl, address _oracle) {
        impl = _impl;
        oracle = IOracle(_oracle);
    }

    function setImpl(address _impl) public onlyOwner {
        impl = _impl;
    }

    function setUnderlying(string memory underlying, bool isSupport) external {
        underlyingList[underlying] = isSupport;
    }

    function setOracle(address _oracle) public onlyOwner {
        oracle = IOracle(_oracle);
    }

    function battleLength() public view returns (uint256 len) {
        len = battleSet.length();
    }

    function getBattle(uint256 index) public view returns (address _battle) {
        _battle = battleSet.at(index);
    }

    function containBattle(address _battle) public view returns (bool) {
        return battleSet.contains(_battle);
    }

    function addBattle(address _battle) public onlyOwner {
        battleSet.add(_battle);
    }

    function removeBattle(address _battle) public onlyOwner {
        battleSet.remove(_battle);
    }

    function tryCreateBattle(
        address _collateral,
        string memory _underlying,
        PeroidType _peroidType,
        SettleType _settleType,
        uint256 _settleValue
    ) public view returns (bool, bytes32) {
        bytes32 paramsHash = keccak256(
            abi.encodePacked(
                _collateral,
                _underlying,
                _peroidType,
                _settleType,
                _settleValue
            )
        );
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
        PeroidType _peroidType,
        SettleType _settleType,
        uint256 _settleValue
    ) public {
        require(_cAmount > 0, 'cAmount 0');
        require(underlyingList[_underlying], 'not support underlying');
        if (_settleType != SettleType.Specific) {
            require(_settleValue % 1e16 == 0, 'Arena::min 1%');
        }
        require(_spearPrice + _shieldPrice == 1e18, 'should 1');

        (bool exist, bytes32 paramsHash) = tryCreateBattle(
            _collateral,
            _underlying,
            _peroidType,
            _settleType,
            _settleValue
        );
        require(!exist, 'params exist');
        paramsExist[paramsHash] = true;
        address battleAddr = Clones.clone(impl);
        battleSet.add(battleAddr);
        IERC20(_collateral).safeTransferFrom(msg.sender, battleAddr, _cAmount);
        IBattle(battleAddr).init(
            _collateral,
            _underlying,
            _cAmount,
            _spearPrice,
            _shieldPrice,
            _peroidType,
            _settleType,
            _settleValue,
            msg.sender,
            address(oracle)
        );
        emit BattleCreated(
            battleAddr,
            _collateral,
            _underlying,
            uint256(_peroidType),
            uint256(_settleType),
            uint256(_settleValue),
            battleSet.length()
        );
    }

    function setBattleFeeTo(address battle, address feeTo) external onlyOwner {
        IBattle(battle).setFeeTo(feeTo);
        emit FeeToChanged(battle, feeTo);
    }

    function setBattleFeeRatio(address battle, uint256 feeRatio)
        external
        onlyOwner
    {
        IBattle(battle).setFeeRatio(feeRatio);
        emit FeeRatioChanged(battle, feeRatio);
    }

    function setSettleReward(address battle, uint256 amount)
        external
        onlyOwner
    {
        IBattle(battle).setSettleReward(amount);
    }
}
