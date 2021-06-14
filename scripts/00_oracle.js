
const { deployProxy, deploy, attach, getMonthTS } = require("./utils");
const { oracleAddr, oracle } = require("../contracts.json")
const fs = require('fs')
const ConGecko = require('coingecko-api')


let contracts = require("../contracts.json");
const CoinGecko = require("coingecko-api");

async function get_oracle() {
	if (oracleAddr === undefined) {
		const oracle = await deployProxy("Oracle")
		console.log(`oracle deploy at ${oracle.address}`)
		contracts['oracleAddr'] = oracle.address 
		let data = JSON.stringify(contracts)
		fs.writeFileSync('../contracts.json', data)
		return oracle
	} else {
		const oracle = await attach("Oracle", oracleAddr)
		console.log(`oracle at ${oracle.address}`)
		return oracle
	}
}

async function initMonthTS() {
	const tsArry = await getMonthTS()
	const oracle = await get_oracle()
	await oracle.setMonthTS(tsArry)
}

async function setPrice() {
	const cg = new CoinGecko()
	let data = await cg.coins.fetchMarketChart('bitcoin')
	let prices = data['data']['prices']
	prices.map((a)=> {
		console.log(`${new Date(a[0]).toJSON()}`)
	})
	// console.log(data['data']['prices'])
}

async function main() {
	// await initMonthTS()
	// const oracle = await get_oracle()
	await setPrice()
}

main().then(() => process.exit(0)).catch(error => {
	console.error(error);
	process.exit(1);
})