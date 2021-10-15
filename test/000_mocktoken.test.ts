import { MockToken } from "../src/types"
import { deploy, deployContract } from "../scripts/utils"
import { expect } from "chai"


describe("deploy mocktoken", () => {

	let dai: MockToken
	const name_symbols = [
		["MockDAI", "DAI", "18"],
		["MockWETH", "WETH", "18"],
		["MockUSDC", "USDC", "6"],
		["MockWBTC", "WBTC", "8"]
	]

	before(async () => {

		for (let i = 0; i < name_symbols.length; i++) {
			let con = await deployContract<MockToken>("MockToken", name_symbols[i][0], name_symbols[i][1], parseInt(name_symbols[i][2]))
			process.env[name_symbols[i][0]] = con.address
		}
	})

	it("token env address not null", () => {
		for (let i = 0; i < name_symbols.length; i++) {
			expect((process.env)[name_symbols[i][0]]).to.exist
		}
	})
})