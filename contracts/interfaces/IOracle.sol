// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../structs/PeriodType.sol";
import "../structs/SettleType.sol";

interface IOracle {
    function price(string memory symbol) external view returns (uint256);

    function historyPrice(string memory symbol, uint256 ts) external view returns (uint256);

    function getStrikePrice(
        string memory symbol,
        PeriodType _pt,
        SettleType _st,
        uint256 _settleValue
    )
        external
        view
        returns (
            uint256 startPrice,
            uint256 strikePrice,
            uint256 strikePriceOver,
            uint256 strikePriceUnder
        );

    function getRoundTS(PeriodType _pt) external view returns (uint256 start, uint256 end);

    function getNextRoundTS(PeriodType _pt) external view returns (uint256 start, uint256 end);

    function updatePriceByExternal(string memory symbol, uint256 ts) external returns (uint256 price_);
}
