const { ethers, upgrades } = require("hardhat");

async function deployProxy(name, ...params) {
	const contractFactory = await ethers.getContractFactory(name);
	return await upgrades.deployProxy(contractFactory, [...params], { kind: 'uups' }).then(f => f.deployed())
}

async function deploy(name, ...params) {
	const contractFactory = await ethers.getContractFactory(name);
	return await contractFactory.deploy(...params).then(f => f.deployed());
}

async function attach(name, addr) {
	return await ethers.getContractAt(name, addr)
}

module.exports.deployProxy = deployProxy
module.exports.deploy = deploy
module.exports.attach = attach