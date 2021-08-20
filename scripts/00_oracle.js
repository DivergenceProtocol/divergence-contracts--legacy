
const { deployProxy, deploy, attach, getMonthTS, getOHLC } = require("./utils");
const fs = require('fs')
const { ethers, upgrades} = require("hardhat");
const { setInterval } = require("timers");
const cons = require("../contracts.json");
const { formatEther } = require("@ethersproject/units");
require('dotenv').config()


let oracleAddr = cons[process.env.TEST_VERSION]['oracleAddr']

console.log(oracleAddr)

// process.exit(0)

let networkID;

function c2json(networkId, name, addr) {
	contracts[networkId][name] =  addr
	let data = JSON.stringify(contracts)
	fs.writeFileSync('../contracts.json', data)
}


async function get_oracle() {
	// let oracleAddr = contracts[networkID]['oracle']
	if (oracleAddr === undefined) {
		const oracle = await deployProxy("Oracle")
		console.log(`oracle deploy at ${oracle.address}`)
		// c2json(networkID, "oracle", oracle.address)
		return oracle
	} else {
		const oracle = await attach("Oracle", oracleAddr)
		console.log(`oracle at ${oracle.address}`)
		return oracle
	}
}

async function initMonthTS(symbols) {
	const tsArry = await getMonthTS()
	const oracle = await get_oracle()
	for (symbol of symbols) {
		// const prices = await getOHLC(symbol, 300*1)
		const prices = await getOHLC(symbol, 3*21*2)
		let tx = await oracle.setMultiPrice(...prices)
		console.log(`pending transaction ${tx.hash} ...`)
		await tx.wait()
	}
	let tx = await oracle.setMonthTS(tsArry)
}

async function upgradeOracle() {
	const Oracle = await ethers.getContractFactory("Oracle")
	await upgrades.upgradeProxy(oracleAddr, Oracle)
}

async function deleteMonTS() {
	const oracle = await get_oracle()
	let tx = await oracle.deleteMonthTS()
	await tx.wait()
}

async function getTS() {
	const oracle = await get_oracle()
	const [start, end] = await oracle.getTS(2, 1)
	console.log(`${new Date(start*1000).toJSON()}, ${new Date(end*1000).toJSON()}`)
	
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function  setExternalOracle() {
	const oracle = await get_oracle()	
	let tx = await oracle.setExternalOracle(['BTC', 'ETH'], ['0x6135b13325bfC4B00278B4abC5e20bbce2D6580e', "0x9326BFA02ADD2366b30bacB125260Af641031331"])
	await tx.wait()
}

async function  getPrice() {
	const oracle = await get_oracle()	
	const price = await oracle.historyPrice('BTC', 1628928000+24*3600*4)
	console.log(`price ${ethers.utils.formatEther(price)}`)
}

async function getTwoPrice(symbol, ts) {
	const oracle = await get_oracle()	
	const chainlink = await attach('AggregatorV3Interface', '0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c')

}

async function setPrice() {
	const oracle = await get_oracle()
	let tx = await oracle.setPrice('BTC', 1627200000, 0)
	await tx.wait()
}

async function getBTCPrice() {
	const oracle = await get_oracle()	
	// const price = await oracle.historyPrice('BTC', 1627200000)
	console.log('waht')
	const p = await oracle.price('BTC')
	console.log(`price ${formatEther(p)}`)

}

async function main() {
	// networkID = (await ethers.provider.getNetwork()).chainId
	// console.log("chainID", networkID)
	// if (contracts[networkID] == undefined) {
	// 	contracts[networkID] = {}
	// }
	// await initMonthTS(["BTCUSDT", "ETHUSDT"])

	// await upgradeOracle()
	// await deleteMonTS()
	// setInterval(await initMonthTS(["BTCUSDT"]), 1000*60)
	// while (true) {
	// 	try {
	// 		await initMonthTS(["BTCUSDT", "ETHUSDT"])
	// 		await sleep(1000*60)
	// 	} catch (error) {
	// 		console.log(`sommething wrong ${error}`)
	// 	}
	// }
	// await initMonthTS(["BTCUSDT", "ETHUSDT"])
	// await initMonthTS(['BTCUSDT'])
	// await setExternalOracle()

	// await getTS()

	// await setPrice()
	await getPrice()
	// await getBTCPrice()
}

main().then(() => process.exit(0)).catch(error => {
	console.error(error);
	process.exit(1);
})