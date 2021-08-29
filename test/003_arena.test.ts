import { parseEther } from "@ethersproject/units"
import { expect } from "chai"
import { ethers } from "ethers"
import { ARENA, BATTLE_IMPL, MOCK_DAI, ORACLE } from "../scripts/const"
import { attach, deployContract, deployProxy } from "../scripts/utils"
import { Arena, MockToken } from "../src/types"



describe("Deploy Arena", () => {
	let arena: Arena
	let dai: MockToken

	before(async () => {
		// arena = (await deployProxy("Arena", process.env.CREATER, process.env.ORACLE)) as Arena
		arena = await deployContract<Arena>('Arena', process.env[BATTLE_IMPL], process.env[ORACLE])
		let daiAddr = process.env[MOCK_DAI]
		dai = await attach<MockToken>('MockToken', daiAddr || '')
		process.env[ARENA] = arena.address

		await dai.approve(arena.address, ethers.constants.MaxUint256)
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

	it('battle length should 0', async () => {
		let battleLen = await arena.battleLength()
		expect(battleLen).to.equal(0);
		console.log(`battle length ${battleLen.toNumber()}`)
	})

	it('try create battle', async () => {
		console.log(`${MOCK_DAI} is ${dai.address}`)
		let [result,] = await arena.tryCreateBattle(dai.address || "", 'BTC', 0, 0, parseEther('0.03'))
		expect(result).to.equal(false)
	})

	it('create battle', async () => {
		let tx = await arena.createBattle(dai.address, 'BTC', parseEther('10000'), parseEther('0.5'), parseEther('0.5'), 0, 0, parseEther('0.03'))
	})

	it('try create battle', async () => {
		console.log(`${MOCK_DAI} is ${dai.address}`)
		let [result,] = await arena.tryCreateBattle(dai.address || "", 'BTC', 0, 0, parseEther('0.03'))
		expect(result).to.equal(true)
	})

})