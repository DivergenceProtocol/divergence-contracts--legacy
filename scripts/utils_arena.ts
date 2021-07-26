import { ethers, network } from "hardhat";
import { Contract } from "ethers";

const getArena = async (): Promise<Contract>=> {
	const networkName = network.name
	const envKey = `ARENA_${networkName.toUpperCase()}`
	console.log(`${envKey}`)
	console.log(`${process.env.ARENA_KOVAN}`)
	const arenaAddr = process.env.envKey?process.env.envKey:"";
	// const arenaAddr = process.env.ARENA_KOVAN?process.env.ARENA_KOVAN:"";
	if (arenaAddr === "") {
		console.error(`arena address env not set`)
		process.exit(1)
	}
	return await ethers.getContractAt("Arena", arenaAddr)
}
export default getArena