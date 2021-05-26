// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../structs/SettleType.sol";
import "../structs/PeroidType.sol";


interface IBattle {
    function buySpear(uint amount) external;
    function sellSpear(uint amount) external;
    function buyShield(uint amount) external;
    function sellShield(uint amount) external;
    function settle(uint price) external;
    function addLiqui(uint amount) external;
    function removeLiqui(uint amount) external;
    function withdraw() external;
    function init0(
        address _collateral,
        address _arena,
        string memory _trackName,
        string memory _priceName,
        PeroidType _peroidType,
        SettleType _settleType,
        uint256 _settleValue
    ) external;

    function init(
        address creater,
        uint256 cAmount,
        uint256 _spearPrice,
        uint256 _shieldPrice,
        address _oracle
    ) external;
}