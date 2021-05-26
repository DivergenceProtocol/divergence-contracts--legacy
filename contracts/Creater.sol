// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Battle.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract Creater {
    
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
        bytes32 bytecodeHash = keccak256(type(Battle).creationCode);
        address battleAddr = Create2.computeAddress(salt, bytecodeHash);
        return (battleAddr, salt);
    }

    function createBattle(bytes32 salt) public {
        Create2.deploy(0, salt, type(Battle).creationCode);
    }


}