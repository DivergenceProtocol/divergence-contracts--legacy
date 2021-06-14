const { ethers, upgrades } = require("hardhat");

const axios = require("axios").default;

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

async function transfer(name, addr, to, amount) {
	const token = await ethers.getContractAt(name, addr)
	const tx = await token.transfer(to, amount)
	await tx.wait()
	console.log(`transfer token to ${to} in tx ${tx.hash}`)
}

async function transferMulti(name, addr, toAddrs, amount) {
	for (const a of toAddrs) {
		await transfer(name, addr, a, amount)
	}
}

async function getMonthTS() {
	let start_str = "2021-06-01T00:00:00.000Z"
	let dt = new Date(start_str)
	let tsArray = []
	for (let i = 5; i < 12; i++) {
		dt.setUTCMonth(i)
		// console.log(dt.toJSON())
		let ts = Math.floor(dt.getTime() / 1000);
		tsArray.push(ts)
	}
	return tsArray
}

async function getOHLC(symbol, limit) {
	let url = `https://api.binance.com/api/v3/klines?symbol=${symbol}&interval=1d&limit=${limit}`
	try {
	    let tsArray = []	
	    let openArray = []
	    let data = (await axios.get(url))['data']
	    data.forEach(element => {
		let ts = Math.floor(element[0] / 1000)	
		tsArray.push(ts)
		// let open = parseFloat(element[1])
		let open = ethers.utils.parseEther(element[1])
		openArray.push(open)
	    });
	    return [symbol.split('USDT')[0], tsArray, openArray]
	} catch (error) {
		console.error(error)
	}
}

module.exports.deployProxy = deployProxy
module.exports.deploy = deploy
module.exports.attach = attach
module.exports.transfer = transfer
module.exports.transferMulti = transferMulti
module.exports.getMonthTS = getMonthTS
module.exports.getOHLC = getOHLC