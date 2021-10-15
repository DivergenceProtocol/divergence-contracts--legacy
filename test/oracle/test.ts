import { MockToken, Oracle } from "../../src/types"
import { deploy, deployContract } from "../../scripts/utils"
import { expect } from "chai"
import { ethers } from "hardhat"


describe("deploy mocktoken", () => {


	it("token env address not null", async () => {
		let oracleAddr = "0x811Ef2F4EbbEBaFe37375b0B1C364f727ccfFF8B"
		let oracle = await ethers.getContractAt("Oracle", oracleAddr) as Oracle
		await oracle.getPriceByExternal('ETH', 1633420800)
	})
})