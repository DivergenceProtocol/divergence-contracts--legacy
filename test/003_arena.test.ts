import { parseEther, formatEther } from "@ethersproject/units"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { BigNumber, BigNumberish } from "ethers"
import { ethers } from "hardhat"
import { format } from "path/posix"
import { ARENA, BATTLE_IMPL, MOCK_DAI, ORACLE } from "../scripts/const"
import { attach, deployContract, deployProxy, setBattleCreaters, setSupportCollateral } from "../scripts/utils"
import { Arena, Battle, ERC20, MockToken } from "../src/types"

async function buySpear(battle: Battle, collateral: ERC20, amount: string) {
	let txApprove = await collateral.approve(battle.address, ethers.constants.MaxUint256)
	await txApprove.wait()
	const spearWillGet = await battle.tryBuySpear(ethers.utils.parseEther(amount))
	let txBuySpear = await battle.buySpear(ethers.utils.parseEther(amount), spearWillGet, Math.floor(new Date().getTime() / 1000) + 24 * 3600 * 2)
	await txBuySpear.wait()
}

async function buyShield(battle: Battle, collateral: ERC20, amount: string) {
	// await battleInfo(battle)
	// let user1 = battle.signer
	// let balance = await collateral.balanceOf(await user1.getAddress())
	// console.log(`before buyShield user ${await user1.getAddress()} dai balance ${formatEther(balance)}`)
	let txApprove = await collateral.approve(battle.address, ethers.constants.MaxUint256)
	await txApprove.wait()
	const shieldWillGet = await battle.tryBuyShield(ethers.utils.parseEther(amount))
	let txBuyShield = await battle.buyShield(ethers.utils.parseEther(amount), shieldWillGet, Math.floor(new Date().getTime() / 1000) + 24 * 3600 * 2)
	await txBuyShield.wait()
	// await battleInfo(battle)
	// balance = await collateral.balanceOf(await user1.getAddress())
	// console.log(`after buyShield user ${await user1.getAddress()} dai balance ${formatEther(balance)} \n`)
}

async function sellShield(battle: Battle, collateral: ERC20, amount: string) {
	// await battleInfo(battle)
	// let user1 = battle.signer
	// let balance = await collateral.balanceOf(await user1.getAddress())
	// console.log(`before sell shield user ${await user1.getAddress()} dai balance ${formatEther(balance)}`)
	const collateralWillGet = await battle.trySellShield(ethers.utils.parseEther(amount))
	let txSellShield = await battle.sellShield(ethers.utils.parseEther(amount), collateralWillGet, Math.floor(new Date().getTime() / 1000) + 24 * 3600 * 2)
	await txSellShield.wait()
	await battleInfo(battle)
	// balance = await collateral.balanceOf(await user1.getAddress())
	// console.log(`after sell shield user ${await user1.getAddress()} dai balance ${formatEther(balance)} \n`)
}

async function battleInfo(battle: Battle): Promise<BigNumber> {
	let cri = await battle.cri()
	let cSpear = await battle.cSpear(cri)
	let cShield = await battle.cShield(cri)
	let cSurplus = await battle.cSurplus(cri)
	let collateral = await battle.collateral(cri)
	let vSpear = await battle.spearBalance(cri, battle.address)
	let vShield = await battle.shieldBalance(cri, battle.address)
	console.log(`cSpear ${formatEther(cSpear)} cShield ${formatEther(cShield)} cSurplus ${formatEther(cSurplus)} collateral ${formatEther(collateral)}`)
	console.log(`vSpear ${formatEther(vSpear)} vShield ${formatEther(vShield)}`)
	let spearPrice = await battle.spearPrice(cri)
	let shieldPrice = await battle.shieldPrice(cri)
	let maxAmountBy1 = cShield.sub(vShield.mul(99).div(100)).mul(100).div(199)
	console.log(`spear price ${formatEther(spearPrice)} shield price ${formatEther(shieldPrice)}`)
	console.log(`maxAmountBy1 of shield: ${formatEther(maxAmountBy1)}`)
	return maxAmountBy1
}


describe("Deploy Arena", () => {
	let arena: Arena
	let dai: MockToken
	let deployer: string
	let user1: SignerWithAddress

	before(async () => {
		// arena = (await deployProxy("Arena", process.env.CREATER, process.env.ORACLE)) as Arena
		console.log(process.env[BATTLE_IMPL])
		console.log(process.env[ORACLE])
		arena = await deployContract<Arena>('Arena', process.env[BATTLE_IMPL], process.env[ORACLE], "0x82C350e3B7A05cd72C9169A3f048FEC42D7C074a")
		let daiAddr = process.env[MOCK_DAI]
		console.log(`dai ${daiAddr}`)
		dai = await attach<MockToken>('MockToken', daiAddr || '')
		// console.log(arena.address)
		process.env[ARENA] = arena.address
		let accounts = await ethers.getSigners()
		deployer = await accounts[0].getAddress()
		user1 = accounts[1]

		await dai.approve(arena.address, ethers.constants.MaxUint256)
	})

	// it("Arena Env Address should not null", () => {
	// 	console.log(1)
	// 	console.log(process.env.ARENA)
	// 	expect(process.env.ARENA).to.equal(process.env.ARENA)
	// })

	it("add underlying should work", async () => {
		console.log(arena.address)
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

	it("add collateral whitelist", async () => {
		await setSupportCollateral(arena, [dai.address], [true])
	})

	it("add battle creater", async () => {
		await setBattleCreaters(arena, [deployer], [true])
	})

	it('battle length should 0', async () => {
		let battleLen = await arena.battleLength()
		expect(battleLen).to.equal(0);
		console.log(`battle length ${battleLen.toNumber()}`)
	})

	it('try create battle', async () => {
		console.log(`${MOCK_DAI} is ${dai.address}`)
		let [result,] = await arena.tryCreateBattle(dai.address || "", 'ETH', 0, 0, parseEther('0.03'))
		expect(result).to.equal(false)
	})

	it('create battle', async () => {
		let tx = await arena.createBattle(dai.address, 'ETH', parseEther('50000'), parseEther('0.5'), parseEther('0.5'), 0, 2, parseEther('0.02'))
		await tx.wait()
		let battleAddr = await arena.getBattle(0)
		await arena.setBattleFeeTo(battleAddr, dai.address)
	})

	it('try buy spear', async () => {
		let battleAddr = await arena.getBattle(0)
		let battle = await attach<Battle>("Battle", battleAddr)
		await buySpear(battle, dai, "1000")
	})

	it('buy and sell', async () => {
		let [result,] = await arena.tryCreateBattle(dai.address || "", 'ETH', 0, 0, parseEther('0.06'))
		expect(result).to.equal(false)
		let txTransfer = dai.transfer(await user1.getAddress(), parseEther("1000000"))
		await (await txTransfer).wait()
		let tx = await arena.createBattle(dai.address, 'ETH', parseEther('10000'), parseEther('0.01'), parseEther('0.99'), 0, 2, parseEther('0.07'))
		await tx.wait()
		let battleAddr = await arena.getBattle(1)
		let battle = await attach<Battle>("Battle", battleAddr)

		// buy shield 
		console.log("buy shield to make cShield / vShield > 0.99")
		await buyShield(battle, dai, "100")
		console.log("after buy shield")
		let cDeltaAmount = (await battleInfo(battle)).mul(10)

		// buy shshield
		console.log("\n buy shield: cDeltaAmount")
		let balance = await dai.balanceOf(await user1.getAddress())
		console.log(`before buy shield user ${await user1.getAddress()} dai balance ${formatEther(balance)}`)
		let battleUser1 = await battle.connect(user1)
		let daiUser1 = dai.connect(user1)
		await buyShield(battleUser1, daiUser1, formatEther(cDeltaAmount))
		balance = await dai.balanceOf(await user1.getAddress())
		console.log(`after buy shield user ${await user1.getAddress()} dai balance ${formatEther(balance)}`)
		await battleInfo(battle)


		// sell shield
		console.log("\n sell shield: cDeltaAmount")
		await sellShield(battleUser1, dai, formatEther(cDeltaAmount))
		balance = await dai.balanceOf(await user1.getAddress())
		console.log(`after sell shield user ${await user1.getAddress()} dai balance ${formatEther(balance)}`)
		await battleInfo(battle)
	})

})