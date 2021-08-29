// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import '../structs/SettleType.sol';
import '../structs/PeroidType.sol';

interface IBattle {
    function buySpear(uint256 amount) external;

    function sellSpear(uint256 amount) external;

    function buyShield(uint256 amount) external;

    function sellShield(uint256 amount) external;

    function settle(uint256 price) external;

    function addLiqui(uint256 amount) external;

    function removeLiqui(uint256 amount) external;

    function withdraw() external;

    function init(
        address _collateral,
        string memory _underlying,
        uint256 _cAmount,
        uint256 _spearPrice,
        uint256 _shieldPrice,
        PeroidType _peroidType,
        SettleType _settleType,
        uint256 _settleValue,
        address battleCreater,
        address _oracle
    ) external;

    function setFeeTo(address feeTo) external;

    function setFeeRatio(uint256 feeRatio) external;

    function setSettleReward(uint256 amount) external;
}
