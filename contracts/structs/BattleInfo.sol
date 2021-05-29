// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PeroidType.sol";
import "./SettleType.sol";

struct BattleInfo {
    string underlying;
    address collateral;
    PeroidType peroidType;
    SettleType settleType;
    uint settleValue;
    uint feeRatio;
}