import { ethers } from "hardhat";
import getArena  from "./utils_arena";


const main = async () => {
	const arena = await getArena()
	const underlyings = ["BTC", "ETH"]
	for (let i=0; i < underlyings.length; i++ ) {
		const tx = await arena.setUnderlying(underlyings[i], true)
		// await tx.deployed()
	}

}

main()
	.then(() => {
		process.exit(0)
	})
	.catch((error) => {
		console.error(error)
		process.exit(1)
	})