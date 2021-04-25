// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RangeType.sol";
import "./RangeResult.sol";

struct RoundInfo {
    uint256 spearPrice;
    uint256 shieldPrice;
    uint256 startPrice;
    uint256 endPrice;
    uint256 startTS;
    uint256 endTS;
    uint256 range;
    RangeType ry;
    uint256 targetPriceUnder;
    uint256 targetPriceSuper;
    RoundResult roundResult;
}
