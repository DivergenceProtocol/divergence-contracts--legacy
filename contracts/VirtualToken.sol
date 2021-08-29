// SPDX-License-Identifier: MIT

// import "hardhat/console.sol";

pragma solidity ^0.8.0;

contract VirtualToken {
    mapping (uint=>uint) public spearTotal;
    mapping(uint => mapping(address=>uint)) public spearBalance;


    mapping (uint=>uint) public shieldTotal;
    mapping(uint => mapping(address=>uint)) public shieldBalance;

    // roundID=>amount
    mapping(uint=>uint) public cSpear;
    mapping(uint=>uint) public cShield;
    mapping(uint=>uint) public collateral;

    // 0 => spear; 1 => shield
    event VTransfer(uint spearOrShield, address from, address to, uint amount);
    event VMint(uint spearOrShield, address to, uint amount);
    event VBurn(uint spearOrShield, address from, uint amount);

    // view
    function spearSold(uint roundId) public view returns(uint){
        return spearTotal[roundId] - spearBalance[roundId][address(this)];
    }

    function shieldSold(uint roundId) public view returns(uint) {
        return shieldTotal[roundId] - shieldBalance[roundId][address(this)];
    }

    function cSurplus(uint roundId) public view returns(uint amount) {
        amount = collateral[roundId] - cSpear[roundId] - cShield[roundId];
    }

    // mut
    function addCSpear(uint roundId, uint amount) internal {
        cSpear[roundId] += amount;
        collateral[roundId] += amount;
    }

    function addCShield(uint roundId, uint amount) internal {
        cShield[roundId] += amount;
        collateral[roundId] += amount;
    }

    function addCSurplus(uint roundId, uint amount) internal {
        collateral[roundId] += amount;
    }

    function subCSpear(uint roundId, uint amount) internal {
        cSpear[roundId] -= amount;
        collateral[roundId] -= amount;
    }

    function subCShield(uint roundId, uint amount) internal {
        cShield[roundId] -= amount;
        collateral[roundId] -= amount;
    }

    function subCSurplus(uint roundId, uint amount) internal {
        collateral[roundId] -= amount;
    }

    function setCSpear(uint roundId, uint amount) internal {
        cSpear[roundId] = amount;
    }

    function setCShield(uint roundId, uint amount) internal {
        cShield[roundId] = amount;
    }

    function addCollateral(uint roundId, uint amount) internal {
        collateral[roundId] += amount;
    }

    function transferSpear(uint roundId, address from, address to, uint amount) internal {
        require(from != address(0), "from should not be address(0)");
        require(to != address(0), "to should not be address(0)");
        spearBalance[roundId][from] -= amount;
        spearBalance[roundId][to] += amount;
        emit VTransfer(0, from, to, amount);
    }

    function transferShield(uint roundId, address from, address to, uint amount) internal {
        require(from != address(0), "from should not be address(0)");
        require(to != address(0), "to should not be address(0)");
        shieldBalance[roundId][from] -= amount;
        shieldBalance[roundId][to] += amount;
        emit VTransfer(1, from, to, amount);
    }

    function burnSpear(uint roundId, address acc, uint amount) internal {
        spearBalance[roundId][acc] -= amount;
        spearTotal[roundId] -= amount;
        emit VBurn(0, acc, amount);
    }

    function burnShield(uint roundId, address acc, uint amount) internal {
        shieldBalance[roundId][acc] -= amount;
        shieldTotal[roundId] -= amount;
        emit VBurn(1, acc, amount);
    }

    function mintSpear(uint roundId, address acc, uint amount) internal {
        spearBalance[roundId][acc] += amount;
        spearTotal[roundId] += amount;
        emit VMint(0, acc, amount);
    }

    function mintShield(uint roundId, address acc, uint amount) internal {
        shieldBalance[roundId][acc] += amount;
        shieldTotal[roundId] += amount;
        emit VMint(1, acc, amount);
    }

}