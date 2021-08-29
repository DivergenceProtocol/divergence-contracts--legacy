// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICreater {
    function getBattleAddress(
        address _collateral,
        string memory _trackName,
        uint256 _peroidType,
        uint256 _settleType,
        uint256 _settleValue
    ) external view returns (address, bytes32);

    function createBattle(bytes32 salt) external;
}
