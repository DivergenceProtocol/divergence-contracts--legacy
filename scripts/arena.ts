import {ERC20} from '../src/types/ERC20'
import {Battle} from '../src/types/Battle'
import {Arena} from '../src/types/Arena'
import { ethers } from 'hardhat'
import { arenaAddr } from '../contracts.json'
import { parseEther } from '@ethersproject/units'
import { BigNumberish } from '@ethersproject/units/node_modules/@ethersproject/bignumber'

const DAI_ADDR = '0x2e4c42c0ea662a87362e7dCa09842e58E14038F2'

async function createBattle(collateralToken: string, underlying: string, cAmount: BigNumberish, spearPrice: string, shieldPrice: string, peroidType: number, settleType: number, settleValue: string) {
	const cToken = await ethers.getContractAt("MockToken", collateralToken) as ERC20
	const arena = await ethers.getContractAt('Arena', arenaAddr) as Arena
	// let tx0 = await cToken.approve(arenaAddr, ethers.constants.MaxUint256)
	// await tx0.wait()

	let txCreateBattle = await arena.createBattle(cToken.address, underlying, cAmount, parseEther(spearPrice), parseEther(shieldPrice), peroidType, settleType, parseEther(settleValue))
	console.log(`create battle ${txCreateBattle.hash}`)
	await txCreateBattle.wait()
}

async function setUnderlyings(arena: Arena, underlyings: string[]) {
	for (let i=0; i < underlyings.length; i++ ) {
		const tx = await arena.setUnderlying(underlyings[i], true)
		await tx.wait()
	}
}

interface Params {
	underlying: string,
	cAmount: BigNumberish,
	spearPrice: string,
	shieldPrice: string,
	peroidType: number,
	settleType: number,
	settleValue: string
}

async function main() {
	// const dai = await ethers.getContractAt('MockToken', DAI_ADDR) as ERC20
	// const arena = await ethers.getContractAt('Arena', arenaAddr) as Arena
	// for (let i=6; i < 50; i++) {
	// 	let value = (i/100).toString()
    // 	let txCreateBattle = await arena.createBattle(dai.address, 'BTC', parseEther("10000"), parseEther("0.45"), parseEther("0.55"), 0, 1, parseEther(value))
	// 	console.log(`create battle ${txCreateBattle.hash}`)
	// 	await txCreateBattle.wait()
	// }
	const params = makeParams()
	for (const p of params) {
		await createBattle(DAI_ADDR, p.underlying, p.cAmount, p.spearPrice, p.shieldPrice, p.peroidType, p.settleType, p.settleValue)
	}
}

function makeParams(): Params[]{
	let params: Params[] = [];
	// const p1: Params = {
	// 	underlying: 'ETH',
	// 	cAmount: parseEther('500000'),
	// 	spearPrice: '0.5',
	// 	shieldPrice: '0.5',
	// 	peroidType: 2,
	// 	settleType: 3,
	// 	settleValue: '2500'
	// }
	// params.push(p1)


	// const p2: Params = {
	// 	underlying: 'ETH',
	// 	cAmount: parseEther('500000'),
	// 	spearPrice: '0.5',
	// 	shieldPrice: '0.5',
	// 	peroidType: 2,
	// 	settleType: 3,
	// 	settleValue: '3000'
	// }
	// params.push(p2)


	const p3: Params = {
		underlying: 'ETH',
		cAmount: parseEther('500000'),
		spearPrice: '0.5',
		shieldPrice: '0.5',
		peroidType: 2,
		settleType: 3,
		settleValue: '3500'
	}
	params.push(p3)


	const p4: Params = {
		underlying: 'ETH',
		cAmount: parseEther('500000'),
		spearPrice: '0.5',
		shieldPrice: '0.5',
		peroidType: 2,
		settleType: 3,
		settleValue: '4000'
	}
	params.push(p4)


	const p5: Params = {
		underlying: 'ETH',
		cAmount: parseEther('500000'),
		spearPrice: '0.5',
		shieldPrice: '0.5',
		peroidType: 1,
		settleType: 3,
		settleValue: '2700'
	}
	params.push(p5)


	const p6: Params = {
		underlying: 'ETH',
		cAmount: parseEther('500000'),
		spearPrice: '0.5',
		shieldPrice: '0.5',
		peroidType: 1,
		settleType: 3,
		settleValue: '3000'
	}
	params.push(p6)


	const p7: Params = {
		underlying: 'ETH',
		cAmount: parseEther('500000'),
		spearPrice: '0.5',
		shieldPrice: '0.5',
		peroidType: 1,
		settleType: 3,
		settleValue: '3200'
	}
	params.push(p7)


	const p8: Params = {
		underlying: 'ETH',
		cAmount: parseEther('500000'),
		spearPrice: '0.5',
		shieldPrice: '0.5',
		peroidType: 1,
		settleType: 3,
		settleValue: '3800'
	}
	params.push(p8)


	const p9: Params = {
		underlying: 'ETH',
		cAmount: parseEther('500000'),
		spearPrice: '0.5',
		shieldPrice: '0.5',
		peroidType: 0,
		settleType: 0,
		settleValue: '0.03'
	}
	params.push(p9)


	const p10: Params = {
		underlying: 'ETH',
		cAmount: parseEther('500000'),
		spearPrice: '0.5',
		shieldPrice: '0.5',
		peroidType: 0,
		settleType: 1,
		settleValue: '0.02'
	}
	params.push(p10)


	const p11: Params = {
		underlying: 'ETH',
		cAmount: parseEther('500000'),
		spearPrice: '0.5',
		shieldPrice: '0.5',
		peroidType: 0,
		settleType: 2,
		settleValue: '0.02'
	}
	params.push(p11)

	return params
}

main().then(() => {
	process.exit(0)
}).catch( err => {
	console.log(err)
	process.exit(1)
})