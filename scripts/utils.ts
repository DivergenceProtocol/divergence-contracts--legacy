import { BigNumber, BigNumberish, Contract } from "ethers";
import { formatEther, parseEther } from "ethers/lib/utils";
import { BigNumber as RawBigNumber } from "bignumber.js"

import { ethers, upgrades } from "hardhat";
import { Battle, ERC20 } from "../src/types";
import { use } from "chai";

const axios = require("axios").default;

export async function deployProxy(name: string, ...params: any[]) {
	const contractFactory = await ethers.getContractFactory(name);

	const con = await upgrades.deployProxy(contractFactory, [...params], { kind: 'uups' })
	await con.deployed()
	console.log(`deploy ${name} proxy at ${con.address}`)
	return con

}

export async function deploy(name: string, ...params: any[]) {
	const contractFactory = await ethers.getContractFactory(name);
	const con = await contractFactory.deploy(...params)
	await con.deployed()
	console.log(`deploy ${name} in ${con.address}`)
	return con
}


export async function deployContract<T>(name: string, ...params: any[]): Promise<T> {
	const contractFactory = await ethers.getContractFactory(name);
	const con = await contractFactory.deploy(...params)
	await con.deployed()
	console.log(`deploy ${name} in ${con.address}`)
	return con as unknown as T
}

export async function attach<T>(name: string, addr: string): Promise<T> {
	return await ethers.getContractAt(name, addr) as unknown as T
}

export async function transfer(name: string, addr: string, to: string, amount: any) {
	const token = await ethers.getContractAt(name, addr)
	const tx = await token.transfer(to, amount)
	await tx.wait()
	console.log(`transfer token to ${to} in tx ${tx.hash}`)
}

export async function transferMulti(name: string, addr: string, toAddrs: string, amount: any) {
	for (const a of toAddrs) {
		await transfer(name, addr, a, amount)
	}
}

export async function getMonthTS() {
	let start_str = "2021-06-01T08:00:00.000Z"
	let dt = new Date(start_str)
	let frids = []
	for (let i = 0; i < 365; i++) {
		dt.setUTCDate(dt.getUTCDate() + 1);
		if (dt.getUTCDay() === 5) {
			frids.push(new Date(dt.getTime()));
			// console.log(dt.toJSON())
		}
	}
	// console.log(frids)
	let last_frids = []
	for (let i = 0; i < frids.length - 1; i++) {
		if (frids[i].getUTCMonth() != frids[i + 1].getUTCMonth()) {
			last_frids.push(frids[i])
			// console.log(frids[i].toJSON())
		}
	}
	// console.log(last_frids)
	let tsArray = []
	for (let i = 0; i < last_frids.length; i++) {
		// dt.setUTCMonth(i)
		// console.log(dt.toJSON())
		let ts = Math.floor(last_frids[i].getTime() / 1000);
		tsArray.push(ts)
	}
	return tsArray
}

export async function getOHLC(symbol: string, limit: number)
// : Promise<[string, BigNumberish[], BigNumberish[]]> 
{
	// let url = `https://api.binance.com/api/v3/klines?symbol=${symbol}&interval=5m&limit=${limit}`
	let url = `https://api.binance.com/api/v3/klines?symbol=${symbol}&interval=8h&limit=${limit}`
	try {
		let tsArray: BigNumberish[] = []
		let openArray: BigNumberish[] = []
		let data = (await axios.get(url))['data']
		data.forEach((element: any) => {
			let ts = Math.floor(element[0] / 1000)
			tsArray.push(ts)
			// let dt = new Date(element[0])
			// console.log(dt.toJSON())
			// let open = parseFloat(element[1])
			let open = ethers.utils.parseEther(element[1])
			openArray.push(open)
		});
		const s1 = symbol.split('USDT')[0]
		const result: [string, BigNumberish[], BigNumberish[]] = [s1, tsArray, openArray]
		//     return [s1, tsArray, openArray]
		return result
	} catch (error) {
		console.error(error)
	}
}

export async function getVirtualTokenPriceStatus(battle: Battle): Promise<[string, string]> {
	const cri = await battle.cri()
	const spearPrice = await battle.spearPrice(cri)
	const shieldprice = await battle.shieldPrice(cri)
	const spearPriceStr = formatEther(spearPrice)
	const shieldPriceStr = formatEther(shieldprice)
	return [spearPriceStr, shieldPriceStr]
}

export interface BattleStatus {
	spearPrice: number;
	shieldPrice: number;
	cSpear: number;
	cShield: number;
	cSurplus: number;
	cTotal: number;
	spearAmount: number;
	shieldAmount: number;
}

function ethersBigNumberToNumber(num: BigNumber, decimals = 18): number {
	return new RawBigNumber(num.toString()).div(new RawBigNumber(`1e${decimals}`)).precision(10).toNumber()
}

export async function getBattleStatus(battle: Battle): Promise<BattleStatus> {

	const cri = await battle.cri()
	const shieldprice = await battle.shieldPrice(cri)
	// const spearPriceNum = Number(spearPrice.div(new RawBigNumber('1e18')).toFixed(8));
	const spearPriceNum = ethersBigNumberToNumber(await battle.spearPrice(cri))
	const shieldPriceNum = ethersBigNumberToNumber(await battle.shieldPrice(cri))
	const cSpear = ethersBigNumberToNumber(await battle.cSpear(cri))
	const cShield = ethersBigNumberToNumber(await battle.cShield(cri))
	const cSurplus = ethersBigNumberToNumber(await battle.cSurplus(cri))
	const cTotal = ethersBigNumberToNumber(await battle.collateral(cri))
	const spearAmount = ethersBigNumberToNumber(await battle.spearBalance(cri, battle.address))
	const shieldAmount = ethersBigNumberToNumber(await battle.shieldBalance(cri, battle.address))
	return {
		spearPrice: spearPriceNum,
		shieldPrice: shieldPriceNum,
		cSpear: cSpear,
		cShield: cShield,
		cSurplus: cSurplus,
		cTotal: cTotal,
		spearAmount: spearAmount,
		shieldAmount: shieldAmount
	}

}

export interface UserStatus {
	spearBalance: number;
	shieldBalance: number;
	collateralBalance: number;
}

export async function getUserStatus(battle: Battle, cToken: ERC20, user: string): Promise<UserStatus> {
	// spear and shield amount	
	const cri = await battle.cri()
	const spearBalance = ethersBigNumberToNumber(await battle.spearBalance(cri, user))
	const shieldBalance = ethersBigNumberToNumber(await battle.shieldBalance(cri, user))
	const collateralBalance = ethersBigNumberToNumber(await cToken.balanceOf(user))
	return {
		spearBalance: spearBalance,
		shieldBalance: shieldBalance,
		collateralBalance: collateralBalance
	}

}