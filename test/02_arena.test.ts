import { expect } from "chai"
import { deployProxy } from "../scripts/utils"
import { Arena } from "../src/types"



describe("Deploy Arena", () => {
	let arena: Arena

	before(async () => {
		arena = (await deployProxy("Arena", process.env.CREATER, process.env.ORACLE)) as Arena
		process.env.ARENA = arena.address
	})

	it("Arena Env Address should not null", () => {
		expect(process.env.ARENA).to.equal(process.env.ARENA)
	})

	it("add underlying should work", async () => {
		const underlyings = ['BTC', 'ETH']
		for (const symbol of underlyings) {
			let tx = await arena.setUnderlying(symbol, true)
			await tx.wait()
		}

		for (const symbol of underlyings) {
			const isTrue = await arena.underlyingList(symbol)
			expect(isTrue).to.equal(true)
		}
	})

})