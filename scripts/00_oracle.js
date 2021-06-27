
const { deployProxy, deploy, attach, getMonthTS, getOHLC } = require("./utils");
const fs = require('fs')
const {oracleAddr} = require("../contracts.json");
const { ethers } = require("hardhat");

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
	// const tsArry = await getMonthTS()
	const oracle = await get_oracle()
	for (symbol of symbols) {
		const prices = await getOHLC(symbol, 26)
		let tx = await oracle.setMultiPrice(...prices)
		console.log(`pending transaction ${tx.hash} ...`)
		await tx.wait()
	}
	// let tx = await oracle.setMonthTS(tsArry)
}

async function main() {
	networkID = (await ethers.provider.getNetwork()).chainId
	console.log("chainID", networkID)
	// if (contracts[networkID] == undefined) {
	// 	contracts[networkID] = {}
	// }
	await initMonthTS(["BTCUSDT", "ETHUSDT"])
}

main().then(() => process.exit(0)).catch(error => {
	console.error(error);
	process.exit(1);
})