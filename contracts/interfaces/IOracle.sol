// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracle {
   function price(string memory symbol) external view returns(uint); 
   function historyPrice(string memory symbol, uint ts) external view returns(uint); 
   function getStrikePrice(string memory symbol, uint _peroidType, uint _settleType, uint256 _settleValue
    ) external  view returns (
            uint256 startPrice,
            uint256 strikePrice,
            uint256 strikePriceOver,
            uint256 strikePriceUnder
        );
   function getRoundTS(uint peroidType) external view returns(uint start, uint end);
   function getNextRoundTS(uint peroidType) external view returns(uint start, uint end);
}