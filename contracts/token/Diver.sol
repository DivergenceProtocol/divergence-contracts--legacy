// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Diver is ERC20Burnable {
    constructor() ERC20("Divergence", "DIVER") {
        _mint(msg.sender, 1000000000e18);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
        require(to != address(this), "Diver::address to is token contract");
    }
}
