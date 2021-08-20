import { ethers } from "hardhat";
import cons from "../contracts.json";
import { Battle } from "../src/types";

require('dotenv').config()

// let test_version:any = process.env.TEST_VERSION?process.env.TEST_VERSION:''
// let arenaAddr: string = cons[test_version]['arenaAddr']

let arenaAddr = '0x7646B69E2Cf598553a69fA3e20Da05ea9F3dfbFc'

async function main() {
	const arena = await ethers.getContractAt("Arena", arenaAddr)
	const battleLen = await arena.battleLength()
	for (let i = 0; i < battleLen; i++) {
		const battle_addr = await arena.getBattle(i)
		const battle = await ethers.getContractAt("Battle", battle_addr) as Battle
		// const peroidType = await battle.peroidType()
		// console.log(peroidType)
		// if (peroidType === 0 || peroidType === 1) {
		// 	let tx = await battle.settle()
		// 	await tx.wait()
		// }
		let cri = await battle.cri()
		let endTS = await battle.endTS(cri)
		if (new Date().getTime()/1000 > endTS.toNumber()) {
			let tx = await battle.settle()
			console.log(`txhash ${tx.hash}`)
			await tx.wait()
		}
	}
}

main().then(() => process.exit(0)).catch(error => {
	console.error(error);
	process.exit(1);
})