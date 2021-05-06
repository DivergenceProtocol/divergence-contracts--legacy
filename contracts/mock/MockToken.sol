// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
   constructor(string memory name, string memory symbol) ERC20(name, symbol){
       _mint(msg.sender, 100000000000*10**18);
   } 

   function mint() external {
       _mint(msg.sender, 10000e18);
   }

   function mintAmount(uint amount) external {
       _mint(msg.sender, amount);
   }
}