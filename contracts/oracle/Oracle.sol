// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

contract Oracle is Initializable, AccessControlEnumerableUpgradeable{
    mapping(string=>uint) public price;
    mapping(string=>mapping(uint=>uint)) public historyPrice;
    bytes32 public ORACLE_ROLE = "oracle_role";

    function initialize() public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ORACLE_ROLE, msg.sender);
    }

    function setPrice(string memory symbol, uint ts, uint _price) public {
        require(hasRole(ORACLE_ROLE, msg.sender), "caller not oracle");
        price[symbol] = _price;
        historyPrice[symbol][ts] = _price;
    }

    function setMultiPrice(string memory symbol, uint[] memory ts, uint[] memory _prices) public {
        require(ts.length == _prices.length, "length should match");
        for(uint i; i < ts.length; i++) {
            setPrice(symbol, ts[i], _prices[i]);
        }
    }

}