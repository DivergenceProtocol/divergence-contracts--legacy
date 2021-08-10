import {ERC20} from '../src/types/ERC20'
import {Battle} from '../src/types/Battle'
import {Arena} from '../src/types/Arena'
import { ethers } from 'hardhat'
import { arenaAddr } from '../contracts.json'
import { parseEther } from '@ethersproject/units'

const DAI_ADDR = '0x2e4c42c0ea662a87362e7dCa09842e58E14038F2'

async function main() {
	const dai = await ethers.getContractAt('MockToken', DAI_ADDR) as ERC20
	const arena = await ethers.getContractAt('Arena', arenaAddr) as Arena
	for (let i=6; i < 50; i++) {
		let value = (i/100).toString()
    	let txCreateBattle = await arena.createBattle(dai.address, 'BTC', parseEther("10000"), parseEther("0.45"), parseEther("0.55"), 0, 1, parseEther(value))
		console.log(`create battle ${txCreateBattle.hash}`)
		await txCreateBattle.wait()
	}
}

main().then(() => {
	process.exit(0)
}).catch( err => {
	console.log(err)
	process.exit(1)
})