// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../structs/SettleType.sol";
import "../structs/PeroidType.sol";
import "../structs/InitParams.sol";

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
        InitParams memory p
    ) external;

    function setFeeTo(address feeTo) external;

    function setFeeRatio(uint256 feeRatio) external;

    function setSettleReward(uint256 amount) external;
}
