import { ethers } from "hardhat";
import { arenaAddr } from "../contracts.json";

async function main() {
	const arena = await ethers.getContractAt("Arena", arenaAddr)
	const battleLen = await arena.battleLength()
	for (let i = 0; i < battleLen; i++) {
		const battle_addr = await arena.getBattle(i)
		const battle = await ethers.getContractAt("Battle", battle_addr)
		const peroidType = await battle.peroidType()
		console.log(peroidType)
		if (peroidType === 0) {
			await battle.settle()
		}
	}
}

main().then(() => process.exit(0)).catch(error => {
	console.error(error);
	process.exit(1);
})