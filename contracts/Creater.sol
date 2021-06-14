// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Battle.sol";

contract Creater {

    address immutable impl;

    constructor() {
        impl = address(new Battle());
    }

    function getBattleAddress(
        address _collateral,
        string memory _trackName,
        uint _peroidType,
        uint _settleType,
        uint256 _settleValue
    ) public view returns(address, bytes32){
         bytes32 salt =
            keccak256(
                abi.encodePacked(
                    _collateral,
                    _trackName,
                    _peroidType,
                    _settleType,
                    _settleValue
                )
            );
        address battleAddr = Clones.predictDeterministicAddress(impl, salt);
        return (battleAddr, salt);
    }

    function createBattle(bytes32 salt) external returns (address) {
        address clone = Clones.cloneDeterministic(impl, salt);
        // Battle(clone).init0(_collateral, _arena, _underlying, _peroidType, _settleType, _settleValue);
        // Battle(clone).init(creater, cAmount, _spearPrice, _shieldPrice, _oracle);
        return clone;
    }

}