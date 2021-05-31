// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

abstract contract VERC1155 is ERC1155Burnable {

    mapping(uint256 => uint256) private _totalSupply;

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override
    { 
        if(from == address(0)) {
            for (uint i; i < ids.length; i++) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }
        if (to == address(0)) {
            for (uint i; i < ids.length; i++) {
                _totalSupply[ids[i]] -= amounts[i];
            }
        }
    }

    function totalSupply(uint256 id) public view returns(uint256) {
        return _totalSupply[id];
    }

    function totalSupplyBatch(uint256[] memory ids) public view returns(uint256[] memory) {
        uint256[] memory batchTotalSupply = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            batchTotalSupply[i] = _totalSupply[ids[i]];
        }
        return batchTotalSupply;
    }
}