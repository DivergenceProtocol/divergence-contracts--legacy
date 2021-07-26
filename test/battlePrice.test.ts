import { ethers, waffle } from "hardhat";
import chai from "chai";
import { Battle } from "../typechain";
import { beforeEach, before } from "mocha";
// import { beforeEach } from "mocha";

describe("Battle Spear/Shield Price", async () => {
	const battle: Battle = await ethers.getContractAt("Battle", "") as Battle;
	const cri = await battle.cri()
	battle.spearPrice(cri)

	before(async () => {
		// deploy and setting oracle
		
		// deploy and setting arena
	})
})