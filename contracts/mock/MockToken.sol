// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
   uint8 private  decimals_;
   constructor(string memory name, string memory symbol, uint8 _decimals) ERC20(name, symbol){
       _mint(msg.sender, 100000000000*10**_decimals);
       decimals_ = _decimals;
   } 

   function mint() external {
       _mint(msg.sender, 10000e18);
   }

   function mintAmount(uint amount) external {
       _mint(msg.sender, amount);
   }

   function decimals() public view virtual override returns (uint8) {
        return decimals_;
    }

}