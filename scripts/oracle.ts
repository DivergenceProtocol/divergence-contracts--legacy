import { Oracle } from "../src/types";
import { deployProxy, getMonthTS, getOHLC } from "./utils";

require('dotenv').config()

import * as cons from "../contracts.json";
import { ethers, upgrades } from "hardhat";
import { formatEther, formatUnits } from "@ethersproject/units";

let oracleAddr='';
switch (process.env.TEST_VERSION) {
	case 'BETA':
		oracleAddr = cons.BETA.oracleAddr
		break
	default:
		console.error("not found version")
}

async function main() {

		let oracle = await getOracle()
		// await setMonthTS(oracle)
		// await setExternalOracle(oracle)
		// await setHistoryPrice(oracle, ['BTCUSDT', 'ETHUSDT'])
		// await setHistoryPrice(oracle, ['ETHUSDT'])

		// await upgradeOracle(oracle)

		// await getPrice(oracle)
		// let [ri, p, updateAt, price] = await oracle.getTest('BTC',  1629705600)
		// console.log(formatUnits(ri, '0'), formatUnits(p, '8'), formatUnits(updateAt, '0'), formatUnits(price, '18'))
}

async function upgradeOracle(oracle:Oracle) {
	const Oracle = await ethers.getContractFactory("Oracle")
	await upgrades.upgradeProxy(oracle.address, Oracle)
}

async function getOracle(): Promise<Oracle> {
	if (oracleAddr === '') {
		const oracle = await deployProxy("Oracle") as Oracle
		console.log(`oracle ${oracle.address}`)
		return oracle
	} else {
		return await ethers.getContractAt("Oracle", oracleAddr) as Oracle
	}
}

async function getPrice(oracle: Oracle) {
	let price = await oracle.getPriceByExternal('BTC', 1629705600)
	console.log(`price is ${formatEther(price)}`)
}

async function setMonthTS(oracle: Oracle) {
	const tsArry = await getMonthTS()
	let tx = await oracle.setMonthTS(tsArry)
	console.log(`tx setMonthTs ${tx.hash}`)
	await tx.wait()
	
}

async function setHistoryPrice(oracle: Oracle, symbols: string[]) {
	for (let symbol of symbols) {
		// const prices = await getOHLC(symbol, 300*1)
		let prices = await getOHLC(symbol, 3*21*2);
		if (prices) {
			let tx = await oracle.setMultiPrice(...prices)
			console.log(`tx setHistoryPrice for ${symbol} ${tx.hash} ...`)
			await tx.wait()
		} else {
			console.log(`setHistoryPrice cant get OHLC`)
		}
	}
}

async function  setExternalOracle(oracle: Oracle) {
	let tx = await oracle.setExternalOracle(['BTC', 'ETH'], ['0x6135b13325bfC4B00278B4abC5e20bbce2D6580e', "0x9326BFA02ADD2366b30bacB125260Af641031331"])
	console.log(`tx setExternalOracle ${tx.hash}`)
	await tx.wait()
}

main()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
	  console.error(error)
	  process.exit(1)
  });
