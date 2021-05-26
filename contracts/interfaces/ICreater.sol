// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICreater {
    function getBattleAddress(
        address _collateral,
        string memory _trackName,
        uint _peroidType,
        uint _settleType,
        uint256 _settleValue
    ) external view returns(address, bytes32);

    function createBattle(bytes32 salt) external;
}