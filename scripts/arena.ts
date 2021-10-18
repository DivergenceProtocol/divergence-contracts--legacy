import {ERC20} from '../src/types/ERC20'
import {Battle} from '../src/types/Battle'
import {Arena} from '../src/types/Arena'
import { ethers } from 'hardhat'
import { formatUnits, parseEther, parseUnits } from '@ethersproject/units'
// import { BigNumberish } from '@ethersproject/units/node_modules/@ethersproject/bignumber'
import { attach, deploy } from './utils'
import { BigNumber, BigNumberish} from '@ethersproject/bignumber'
import { MockToken } from '../src/types'

const addrConfig = require("../contracts.json")

require('dotenv').config();


let arenaAddr: string, daiAddr: string, oracleAddr: string, usdcAddr: string;
let version = process.env.TEST_VERSION!;
arenaAddr = addrConfig[version]['arenaAddr']
daiAddr = addrConfig[version]['daiAddr']
usdcAddr = addrConfig[version]['usdcAddr']
oracleAddr = addrConfig[version]['oracleAddr']

console.log(`${version} has arena ${arenaAddr} dai ${daiAddr} usdc ${usdcAddr} oracle ${oracleAddr}`)

async function deployBattleImpl(): Promise<Battle> {
	return await deploy<Battle>("Battle")	
}

async function deployArena(): Promise<Arena> {
	let battle = await deployBattleImpl()
	return await deploy('Arena', battle.address, oracleAddr, "0x82C350e3B7A05cd72C9169A3f048FEC42D7C074a")
}

async function getArena(): Promise<Arena> {
	if (arenaAddr === '') {
		return await deployArena()
	} else {
		return await attach('Arena', arenaAddr)
	}
}
async function createBattle(arena: Arena, collateralToken: string, underlying: string, cAmount: BigNumberish, spearPrice: string, shieldPrice: string, periodType: number, settleType: number, settleValue: string, user: string) {
	const cToken = await ethers.getContractAt("MockToken", collateralToken) as ERC20
	// let tx0 = await cToken.approve(arena.address, ethers.constants.MaxUint256)

	let [success, info] = await arena.tryCreateBattle(cToken.address, underlying, periodType, settleType, parseEther(settleValue))
	console.log(`try create ${success} of ${info}`)
	let txCreateBattle = await arena.createBattle(cToken.address, underlying, cAmount, parseEther(spearPrice), parseEther(shieldPrice), periodType, settleType, parseEther(settleValue))
	console.log(`create battle ${txCreateBattle.hash}`)
	await txCreateBattle.wait(3)
}

async function setUnderlyings(arena: Arena, underlyings: string[]) {
	for (let i=0; i < underlyings.length; i++ ) {
		let isSupport = await arena.underlyingList(underlyings[i])
		if (isSupport === false) {
			const tx = await arena.setUnderlying(underlyings[i], true)
			await tx.wait()
		}
	}
}

async function setSupportCollateral(arena: Arena, collateal: string[], states: boolean[]) {
	if (collateal.length != states.length) {
		console.error(`set support collateral length not match`)
		process.exit(-1)
	}
	for (let i=0; i < collateal.length; i++) {
		let tx = await arena.setSupportedCollateal(collateal[i], states[i])
		await tx.wait()
	}
}

async function setOracle() {
	let arena = await ethers.getContractAt("Arena", "0x03CCa967FEc8587faa6D57903db6A322B763ca1E")	as Arena
	await arena.setOracle("0x811Ef2F4EbbEBaFe37375b0B1C364f727ccfFF8B")
}
interface Params {
	underlying: string,
	cAmount: BigNumberish,
	spearPrice: string,
	shieldPrice: string,
	periodType: number,
	settleType: number,
	settleValue: string
}


function makeParams(cDecimal: number): Params[]{
	let params: Params[] = [];
	for (let i=0; i < 3; i++) {
		let settleValue = 0.01 + (i*0.01)
		let p: Params = {
			underlying: 'ETH',
			cAmount: parseUnits('50000', cDecimal),
			spearPrice: '0.5',
			shieldPrice: '0.5',
			periodType: 0,
			settleType: 1,
			settleValue: settleValue.toString()
		}
		params.push(p)
	}


	for (let i=0; i < 2; i++) {
		let settleValue = 60000 + (i*2000)
		let p: Params = {
			underlying: 'BTC',
			cAmount: parseUnits('50000', cDecimal),
			spearPrice: '0.5',
			shieldPrice: '0.5',
			periodType: 0,
			settleType: 3,
			settleValue: settleValue.toString()
		}
		params.push(p)
	}

	return params
}


async function main() {
	// const dai = await ethers.getContractAt('MockToken', DAI_ADDR) as ERC20
	// const arena = await ethers.getContractAt('Arena', arenaAddr) as Arena
	// const arena = await getArena()
	// console.log(`use arena ${arena.address}`)
	// // await setUnderlyings(arena, ['BTC', 'ETH'])
	// const params = makeParams()
	// for (const p of params) {
	// 	await createBattle(arena, daiAddr, p.underlying, p.cAmount, p.spearPrice, p.shieldPrice, p.periodType, p.settleType, p.settleValue)
	// }

	// await setOracle()

	// For arbitrum rinkeby
	const arena = await getArena()
	// let [deployer] = await ethers.getSigners()
	// let deployerAddr = await deployer.getAddress()
	// console.log(`use arena ${arena.address.toLowerCase()} deployer ${deployerAddr}`)
	// let mt = await attach("MockToken", usdcAddr) as MockToken
	// let bal = await mt.balanceOf(deployerAddr)
	// console.log(`${formatUnits(bal, 6)}`)
	// let txApprove = await mt.approve(arena.address, ethers.constants.MaxUint256)
	// let allow = await mt.allowance(deployerAddr, arena.address)
	// console.log(`${formatUnits(allow, 6)}`)
	// await setUnderlyings(arena, ['BTC', 'ETH'])
	// await setSupportCollateral(arena, [mt.address], [true])
	// let tx1 = await arena.setBattleCreater("0x22ca9b22095de647c28debc4dea2cb252dfd531a", true)
	// await tx1.wait(3)
	// let tx2 = await arena.setBattleCreater("0x466043D6644886468E8E0ff36dfAF0060aEE7d37", true)
	// await tx2.wait(3)
	// const params = makeParams(6)
	// for (const p of params) {
	// 	await createBattle(arena, usdcAddr, p.underlying, p.cAmount, p.spearPrice, p.shieldPrice, p.periodType, p.settleType, p.settleValue, deployerAddr)
	// }

	await setBattleCreaters(arena, ["0x990A294Bc162e00A4a43488C10B26641b3B174AB"], [true])

}

async function setBattleCreaters(arena: Arena, creaters: string[], states: boolean[]) {
	let tx = await arena.setMutiBattleCreater(creaters, states)	
	await tx.wait()
}

main().then(() => {
	process.exit(0)
}).catch( err => {
	console.log(err)
	process.exit(1)
})