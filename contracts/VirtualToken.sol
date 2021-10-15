// SPDX-License-Identifier: MIT

// import "hardhat/console.sol";

pragma solidity ^0.8.0;

contract VirtualToken {
    mapping(uint256 => uint256) public spearTotal;
    mapping(uint256 => mapping(address => uint256)) public spearBalance;

    mapping(uint256 => uint256) public shieldTotal;
    mapping(uint256 => mapping(address => uint256)) public shieldBalance;

    // ri=>amount
    mapping(uint256 => uint256) public cSpear;
    mapping(uint256 => uint256) public cShield;
    mapping(uint256 => uint256) public collateral;

    // 0 => spear; 1 => shield
    event VTransfer(address indexed from, address indexed to, uint256 ri, uint256 spearOrShield, uint256 value);

    // view
    function spearSold(uint256 ri) public view returns (uint256) {
        return spearTotal[ri] - spearBalance[ri][address(this)];
    }

    function shieldSold(uint256 ri) public view returns (uint256) {
        return shieldTotal[ri] - shieldBalance[ri][address(this)];
    }

    function cSurplus(uint256 ri) public view returns (uint256 amount) {
        amount = collateral[ri] - cSpear[ri] - cShield[ri];
    }

    // mut
    function addCSpear(uint256 ri, uint256 amount) internal {
        cSpear[ri] += amount;
        collateral[ri] += amount;
    }

    function addCShield(uint256 ri, uint256 amount) internal {
        cShield[ri] += amount;
        collateral[ri] += amount;
    }

    function addCSurplus(uint256 ri, uint256 amount) internal {
        collateral[ri] += amount;
    }

    function subCSpear(uint256 ri, uint256 amount) internal {
        cSpear[ri] -= amount;
        collateral[ri] -= amount;
    }

    function subCShield(uint256 ri, uint256 amount) internal {
        cShield[ri] -= amount;
        collateral[ri] -= amount;
    }

    function subCSurplus(uint256 ri, uint256 amount) internal {
        collateral[ri] -= amount;
    }

    function setCSpear(uint256 ri, uint256 amount) internal {
        cSpear[ri] = amount;
    }

    function setCShield(uint256 ri, uint256 amount) internal {
        cShield[ri] = amount;
    }

    function addCollateral(uint256 ri, uint256 amount) internal {
        collateral[ri] += amount;
    }

    function transferSpear(
        uint256 ri,
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "from should not be address(0)");
        require(to != address(0), "to should not be address(0)");
        spearBalance[ri][from] -= amount;
        spearBalance[ri][to] += amount;
        emit VTransfer(from, to, ri, 0, amount);
    }

    function transferShield(
        uint256 ri,
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "from should not be address(0)");
        require(to != address(0), "to should not be address(0)");
        shieldBalance[ri][from] -= amount;
        shieldBalance[ri][to] += amount;
        emit VTransfer(from, to, ri, 1, amount);
    }

    function burnSpear(
        uint256 ri,
        address acc,
        uint256 amount
    ) internal {
        spearBalance[ri][acc] -= amount;
        spearTotal[ri] -= amount;
        emit VTransfer(acc, address(0), ri, 0, amount);
    }

    function burnShield(
        uint256 ri,
        address acc,
        uint256 amount
    ) internal {
        shieldBalance[ri][acc] -= amount;
        shieldTotal[ri] -= amount;
        emit VTransfer(acc, address(0), ri, 1, amount);
    }

    function mintSpear(
        uint256 ri,
        address acc,
        uint256 amount
    ) internal {
        spearBalance[ri][acc] += amount;
        spearTotal[ri] += amount;
        emit VTransfer(address(0), acc, ri, 0, amount);
    }

    function mintShield(
        uint256 ri,
        address acc,
        uint256 amount
    ) internal {
        shieldBalance[ri][acc] += amount;
        shieldTotal[ri] += amount;
        emit VTransfer(address(0), acc, ri, 1, amount);
    }
}
