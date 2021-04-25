// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOracle {
   function price(string memory symbol) external returns(uint); 
}