// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct UserInfo {
    string underingName;
    uint settleType;
    uint settleValue;
    uint[] strikePrice;
    uint[] strikePriceOver;
    uint[] strikePriceUnder;
    uint[] roundIds;
    uint[] spearBalances;
    uint[] shieldBalances;
    uint[] endTS;
    uint[] result;
}