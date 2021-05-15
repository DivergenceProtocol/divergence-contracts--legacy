// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../structs/PeroidType.sol";
import "../structs/SettleType.sol";

interface IArena {
    function getPeroidTS(PeroidType peroidType)
        external
        view
        returns (uint256, uint256);

    function getSpacePrice(uint256 oraclePrice, uint256 rawPrice)
        external
        pure
        returns (uint256 price);

    function getStrikePrice(
        string memory symbol,
        PeroidType _peroidType,
        SettleType _settleType,
        uint256 _settleValue
    )
        external
        returns (
            uint256 startPrice,
            uint256 strikePrice,
            uint256 strikePriceOver,
            uint256 strikePriceUnder
        );

   function getPriceByTS(string memory symbol, uint ts) external view returns(uint);
}
