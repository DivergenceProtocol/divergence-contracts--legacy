// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PeroidType.sol";
import "./SettleType.sol";
import "./RoundResult.sol";

struct RoundInfo {
    uint spearPrice;
    uint shieldPrice;
    uint strikePrice;
    uint strikePriceOver;
    uint strikePriceUnder;
    uint startTS;
    uint endTS;
    RoundResult result;
}