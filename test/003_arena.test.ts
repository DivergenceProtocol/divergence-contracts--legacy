import { parseEther } from "@ethersproject/units"
import { expect } from "chai"
import { ethers } from "ethers"
import { ARENA, BATTLE_IMPL, MOCK_DAI, ORACLE } from "../scripts/const"
import { attach, deployContract, deployProxy } from "../scripts/utils"
import { Arena, Battle, ERC20, MockToken } from "../src/types"

async function buySpear(battle: Battle, collateral: ERC20, amount: string) {
	let txApprove = await collateral.approve(battle.address, ethers.constants.MaxUint256)
	await txApprove.wait()
	const spearWillGet = await battle.tryBuySpear(ethers.utils.parseEther(amount))
	let txBuySpear = await battle.buySpear(ethers.utils.parseEther(amount), spearWillGet, Math.floor(new Date().getTime()/1000)+24*3600*2)
	await txBuySpear.wait()
}


describe("Deploy Arena", () => {
	let arena: Arena
	let dai: MockToken

	before(async () => {
		// arena = (await deployProxy("Arena", process.env.CREATER, process.env.ORACLE)) as Arena
		arena = await deployContract<Arena>('Arena', process.env[BATTLE_IMPL], process.env[ORACLE], "0x82C350e3B7A05cd72C9169A3f048FEC42D7C074a")
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
		// let tx = await arena.createBattle(dai.address, 'BTC', parseEther('10000'), parseEther('0.5'), parseEther('0.5'), 0, 0, parseEther('0.03'))
		let tx = await arena.createBattle(dai.address, 'BTC', parseEther('50000'), parseEther('0.5'), parseEther('0.5'), 0, 2, parseEther('0.02'))
		let battleAddr = await arena.getBattle(0)
		await arena.setBattleFeeTo(battleAddr, dai.address)
	})

	// it('try create battle', async () => {
	// 	console.log(`${MOCK_DAI} is ${dai.address}`)
	// 	let [result,] = await arena.tryCreateBattle(dai.address || "", 'BTC', 0, 0, parseEther('0.03'))
	// 	expect(result).to.equal(true)
	// })

	it('try buy spear', async () => {
		let battleAddr = await arena.getBattle(0)
		let battle = await attach<Battle>("Battle", battleAddr)
		// let collateral = await attach<ERC20>("ERC20", "0x2e4c42c0ea662a87362e7dCa09842e58E14038F2")
		await buySpear(battle, dai, "1000")
	})

})