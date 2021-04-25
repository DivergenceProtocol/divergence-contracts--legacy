// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./Battle.sol";
import "./structs/RangeType.sol";

pragma solidity ^0.8.0;

contract Arena {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private battleSet;

    mapping(address=>bool) public approved;

    function battleLength() public view returns (uint256 len) {

        len = battleSet.length();
    }

    function addBattle(address _battle) public {
        battleSet.add(_battle);
    }

    function getBattle(uint index) public view returns(address _battle) {
        _battle = battleSet.at(index);
    } 

    function removeBattle(address _battle) public {
        battleSet.remove(_battle);
    }

    function containBattle(address _battle) public view returns(bool){
        return battleSet.contains(_battle);
    }

    // function createBattle(
    //     address  _collateral,
    //     IOracle _oracle,
    //     string memory _trackName,
    //     uint256 amount,
    //     uint256 _spearPrice,
    //     uint256 _shieldPrice,
    //     uint256 _range,
    //     RangeType _ry,
    //     uint256 _startTS,
    //     uint256 _endTS
    // ) public {
    //     IERC20Upgradeable(_collateral).safeTransferFrom(msg.sender, address(this), amount);
    //     bytes32 salt = keccak256(abi.encodePacked(_collateral, _trackName, block.timestamp));
    //     address battle =
    //         Create2Upgradeable.deploy(
    //             0,
    //             salt,
    //             type(Battle).creationCode
    //         );
    //     if (!approved[_collateral]) {
    //         IERC20Upgradeable(_collateral).safeApprove(battle, 2**256-1);
    //     }
    //     IERC20Upgradeable(_collateral).safeTransfer(battle, amount);
    //     Battle(battle).init(_collateral, _oracle, _trackName, amount, _spearPrice, _shieldPrice, _range, _ry, _startTS, _endTS);
    // }
}
