// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PeroidType.sol";
import "./SettleType.sol";

struct InitParams {
    address _collateral;
    string _underlying;
    uint256 _cAmount;
    uint256 _spearPrice;
    uint256 _shieldPrice;
    PeroidType _peroidType;
    SettleType _settleType;
    uint256 _settleValue;
    address battleCreater;
    address _oracle;
    address _feeTo;
}
