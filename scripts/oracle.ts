import { Oracle } from "../src/types";
import { deployProxy, getMonthTS, getOHLC } from "./utils";

require('dotenv').config()

import * as cons from "../contracts.json";
import { ethers, network, upgrades } from "hardhat";
import { formatEther, formatUnits, parseEther } from "@ethersproject/units";
import { BigNumber } from "@ethersproject/bignumber";

let oracleAddr='';
switch (process.env.TEST_VERSION) {
	case 'BETA':
		oracleAddr = cons.BETA.oracleAddr
		break
	case 'DEV':
		oracleAddr = cons.DEV.oracleAddr
		// oracleAddr = ''
		break
	case 'ARBI_TEST':
		oracleAddr = cons.ARBI_TEST.oracleAddr
		break
	default:
		console.error("not found version")
}

async function main() {

		let oracle = await getOracle()

		// await setMonthTS(oracle)
		// await setExternalOracle(oracle, network.name)
		await setHistoryPrice(oracle, ['BTCUSDT', 'ETHUSDT'])
		// let [start, end] = await oracle.getRoundTS(0)
		// console.log(oracle.address)
		// await upgradeOracle(oracle)

		// console.log(`start ${new Date(parseInt(formatUnits(start, 0))*1000)} end ${formatUnits(end, 0)}`)
		// await chainlink()
		// await getPrice(oracle, 'ETH', 1634886000)
		// await getPrice(oracle, 'BTC', 1633420800)
		// await setHistoryPrice(oracle, ['ETHUSDT'])

		// await upgradeOracle(oracle)

		// await getPrice(oracle)
		// let [ri, p, updateAt, price] = await oracle.getTest('BTC',  1629705600)
		// console.log(formatUnits(ri, '0'), formatUnits(p, '8'), formatUnits(updateAt, '0'), formatUnits(price, '18'))

		// await chainlink()

		// let [start, end] = await oracle.getRoundTS(0)
		// console.log(`${formatUnits(start, 0)}`)
		// console.log(`${new Date(Number(formatUnits(start, 0))*1000)}`)
		// console.log(`${new Date(Number(formatUnits(end, 0))*1000)}`)
		// // let tx = await oracle.updatePriceByExternal('ETH', start)
		// // tx.wait()
		// let startPrice = await oracle.historyPrice('ETH', 1634814000)
		// console.log(`${formatUnits(startPrice, 18)}`)
		// // let [startPrice , strikePrice, strikePriceOver, strikePriceUnder] = await oracle.getStrikePrice('ETH', 0, 0, parseEther("0.01"))
		// // console.log(`${formatUnits(startPrice, 18)}`)
		// // console.log(`${formatUnits(strikePrice, 18)}`)
		// // console.log(`${formatUnits(strikePriceOver, 18)}`)
		// // console.log(`${formatUnits(strikePriceUnder, 18)}`)
		// let price = await oracle.getPriceByExternal('ETH', start)
		// console.log(`${formatUnits(price, 18)}`)
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

async function getPrice(oracle: Oracle, symbol: string, ts: number) {
	let price = await oracle.getPriceByExternal(symbol, ts)
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
		let prices = await getOHLC(symbol, 24*4);
		if (prices) {
			let tx = await oracle.setMultiPrice(...prices)
			console.log(`tx setHistoryPrice for ${symbol} ${tx.hash} ...`)
			await tx.wait()
		} else {
			console.log(`setHistoryPrice cant get OHLC`)
		}
	}
}

async function  setExternalOracle(oracle: Oracle, network: string) {
	let tx
	console.log("oracle network ", network)
	switch (network) {

		case "arbi_test":
			tx = await oracle.setExternalOracle(['BTC', 'ETH'], ['0x0c9973e7a27d00e656B9f153348dA46CaD70d03d', "0x5f0423B1a6935dc5596e7A24d98532b67A0AeFd8"])
			break
		case "kovan":
			tx = await oracle.setExternalOracle(['BTC', 'ETH'], ['0x6135b13325bfC4B00278B4abC5e20bbce2D6580e', "0x9326BFA02ADD2366b30bacB125260Af641031331"])
			break 
		default:
			console.error("not know network")
			process.exit(-1)
	}
	console.log(`tx setExternalOracle ${tx.hash}`)
	await tx.wait()
}

async function chainlink() {
	// let ethOracle = "0x9326BFA02ADD2366b30bacB125260Af641031331"
	// let ethOracle = "0x5f0423B1a6935dc5596e7A24d98532b67A0AeFd8"
	let ethOracle = "0x0c9973e7a27d00e656B9f153348dA46CaD70d03d"

	let abi = [{"inputs":[{"internalType":"address","name":"_aggregator","type":"address"},{"internalType":"address","name":"_accessController","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"int256","name":"current","type":"int256"},{"indexed":true,"internalType":"uint256","name":"roundId","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"updatedAt","type":"uint256"}],"name":"AnswerUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"roundId","type":"uint256"},{"indexed":true,"internalType":"address","name":"startedBy","type":"address"},{"indexed":false,"internalType":"uint256","name":"startedAt","type":"uint256"}],"name":"NewRound","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"}],"name":"OwnershipTransferRequested","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"inputs":[],"name":"acceptOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"accessController","outputs":[{"internalType":"contract AccessControllerInterface","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"aggregator","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_aggregator","type":"address"}],"name":"confirmAggregator","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"description","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_roundId","type":"uint256"}],"name":"getAnswer","outputs":[{"internalType":"int256","name":"","type":"int256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint80","name":"_roundId","type":"uint80"}],"name":"getRoundData","outputs":[{"internalType":"uint80","name":"roundId","type":"uint80"},{"internalType":"int256","name":"answer","type":"int256"},{"internalType":"uint256","name":"startedAt","type":"uint256"},{"internalType":"uint256","name":"updatedAt","type":"uint256"},{"internalType":"uint80","name":"answeredInRound","type":"uint80"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_roundId","type":"uint256"}],"name":"getTimestamp","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"latestAnswer","outputs":[{"internalType":"int256","name":"","type":"int256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"latestRound","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"latestRoundData","outputs":[{"internalType":"uint80","name":"roundId","type":"uint80"},{"internalType":"int256","name":"answer","type":"int256"},{"internalType":"uint256","name":"startedAt","type":"uint256"},{"internalType":"uint256","name":"updatedAt","type":"uint256"},{"internalType":"uint80","name":"answeredInRound","type":"uint80"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"latestTimestamp","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address payable","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint16","name":"","type":"uint16"}],"name":"phaseAggregators","outputs":[{"internalType":"contract AggregatorV2V3Interface","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"phaseId","outputs":[{"internalType":"uint16","name":"","type":"uint16"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_aggregator","type":"address"}],"name":"proposeAggregator","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"proposedAggregator","outputs":[{"internalType":"contract AggregatorV2V3Interface","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint80","name":"_roundId","type":"uint80"}],"name":"proposedGetRoundData","outputs":[{"internalType":"uint80","name":"roundId","type":"uint80"},{"internalType":"int256","name":"answer","type":"int256"},{"internalType":"uint256","name":"startedAt","type":"uint256"},{"internalType":"uint256","name":"updatedAt","type":"uint256"},{"internalType":"uint80","name":"answeredInRound","type":"uint80"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"proposedLatestRoundData","outputs":[{"internalType":"uint80","name":"roundId","type":"uint80"},{"internalType":"int256","name":"answer","type":"int256"},{"internalType":"uint256","name":"startedAt","type":"uint256"},{"internalType":"uint256","name":"updatedAt","type":"uint256"},{"internalType":"uint80","name":"answeredInRound","type":"uint80"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_accessController","type":"address"}],"name":"setController","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_to","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"version","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]
	let cOracle = await ethers.getContractAt(abi, ethOracle)
	let [roundId,] = await cOracle.latestRoundData()
	let roundIdStr = ethers.utils.formatUnits(roundId, 0)
	console.log(roundIdStr)
	for (let i=0; i < 100; i++) {
		let [ri,answer,start, update, ] = await cOracle.getRoundData(roundId.sub(BigNumber.from(i)))
		answer = ethers.utils.formatUnits(answer, 8)
		start = Number(ethers.utils.formatUnits(start, 0)) * 1000
		update = Number(ethers.utils.formatUnits(update, 0)) * 1000
		ri = ethers.utils.formatUnits(ri, 0)
		console.log(` ${ri} ${start/1000} ${update/1000} ${new Date(start)} ${answer}`)
	}
}

main()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
	  console.error(error)
	  process.exit(1)
  });
