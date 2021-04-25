// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBattle {
    function init(uint amount, uint price0, uint pirce1, uint price2, uint endTs) external;
    function buySpear(uint amount) external;
    function sellSpear(uint amount) external;
    function buyShield(uint amount) external;
    function sellShield(uint amount) external;
    function settle(uint price) external;
    function addLiqui(uint amount) external;
    function removeLiqui(uint amount) external;
    function withdraw() external;
}