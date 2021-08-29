import { formatUnits } from "@ethersproject/units";
import { ethers } from "hardhat";
import cons from "../contracts.json";
import { Battle } from "../src/types";

require('dotenv').config()

// let test_version:any = process.env.TEST_VERSION?process.env.TEST_VERSION:''
// let arenaAddr: string = cons[test_version]['arenaAddr']

// let arenaAddr = '0x7646B69E2Cf598553a69fA3e20Da05ea9F3dfbFc'
let arenaAddr = '0x03CCa967FEc8587faa6D57903db6A322B763ca1E'

async function main() {
	const arena = await ethers.getContractAt("Arena", arenaAddr)
	const battleLen = await arena.battleLength()
	let excludeAddrs = ['0x4c518DD82D45c6c985D558034b36F3922e43Cb2B', '0x4181ed4De29079B39Ee0EfF08D29CC2Ea3a810bB',
		'0xab77972f6b3eb8e3531b1cf674a14d34dcc727e1',
		'0xa1Aca81B0d13A9EA4824a8db66eEfd8E66874Ec2',
		'0xd716d25349d5516304cddbd7b88b92769db08dec'
	].map((addr) => addr.toLowerCase())
	console.log('battle length ', formatUnits(battleLen, '0'))
	for (let i = 0; i < battleLen; i++) {
		const battle_addr = await arena.getBattle(i)
		const battle = await ethers.getContractAt("Battle", battle_addr) as Battle
		// const peroidType = await battle.peroidType()
		// console.log(peroidType)
		// if (peroidType === 0 || peroidType === 1) {
		// 	let tx = await battle.settle()
		// 	await tx.wait()
		// }
		// if (battle.address === '0x4c518DD82D45c6c985D558034b36F3922e43Cb2B' || battle.address === '0x4181ed4De29079B39Ee0EfF08D29CC2Ea3a810bB') {
		// 	continue
		// }
		if (excludeAddrs.includes(battle.address.toLowerCase())) {
			continue
		}
		let cri = await battle.cri()
		let endTS = await battle.endTS(cri)
		if (new Date().getTime() / 1000 > endTS.toNumber()) {
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