import { attach, getBattleStatus, getUserStatus, getVirtualTokenPriceStatus } from "../scripts/utils"
import { Arena, Battle, Creater, MockToken, Oracle } from "../src/types"
import { ethers } from "hardhat";
import { formatEther, parseEther } from "ethers/lib/utils";
import { BigNumber, Signer } from "ethers";
import { expect } from "./shared/expect"
import { randomInt } from "crypto";


async function buySpear(battle: Battle, amount: number) {
	const willGet = await battle.tryBuySpear(parseEther(amount.toString()))
	const tx0 = await battle.buySpear(parseEther(amount.toString()), willGet, new Date().getTime())
	await tx0.wait()
	// const [spearPrice, shieldPrice] = await getVirtualTokenPriceStatus(battle)
	// expect(parseEther(spearPrice).add(parseEther(shieldPrice))).to.equal(parseEther("0.999999999999999999"))
	// expect(parseEther(spearPrice).add(parseEther(shieldPrice))).to.equal(parseEther("1"))
	// console.log(`spear price ${spearPrice}, shield price ${shieldPrice}`)
	const status = await getBattleStatus(battle)
	console.log(status)
	return status
}


async function sellSpear(battle: Battle, amount: number) {
	const willGet = await battle.trySellSpear(parseEther(amount.toString()))
	const tx0 = await battle.sellSpear(parseEther(amount.toString()), willGet, new Date().getTime())
	await tx0.wait()
	// const [spearPrice, shieldPrice] = await getVirtualTokenPriceStatus(battle)
	// expect(parseEther(spearPrice).add(parseEther(shieldPrice))).to.equal(parseEther("0.999999999999999999"))
	// expect(parseEther(spearPrice).add(parseEther(shieldPrice))).to.equal(parseEther("1"))
	// console.log(`spear price ${spearPrice}, shield price ${shieldPrice}`)
	const status = await getBattleStatus(battle)
	console.log(status)
	return status
}


async function buyShield(battle: Battle, amount: number) {
	const willGetShield = await battle.tryBuyShield(parseEther(amount.toString()))
	const tx1 = await battle.buyShield(parseEther(amount.toString()), willGetShield, new Date().getTime())
	await tx1.wait()
	// const [spearPrice1, shieldPrice1] = await getVirtualTokenPriceStatus(battle)
	// console.log(`spear price ${spearPrice1}, shield price ${shieldPrice1}`)
	// expect(parseEther(spearPrice1).add(parseEther(shieldPrice1))).to.equal(parseEther("0.999999999999999999"))
	// expect(parseEther(spearPrice1).add(parseEther(shieldPrice1))).to.equal(parseEther("1"))
	const status = await getBattleStatus(battle)
	console.log(status)
	return status
}

async function sellShield(battle: Battle, amount: number) {
	const willGetShield = await battle.trySellShield(parseEther(amount.toString()))
	const tx1 = await battle.sellShield(parseEther(amount.toString()), willGetShield, new Date().getTime())
	await tx1.wait()
	// const [spearPrice1, shieldPrice1] = await getVirtualTokenPriceStatus(battle)
	// console.log(`spear price ${spearPrice1}, shield price ${shieldPrice1}`)
	// expect(parseEther(spearPrice1).add(parseEther(shieldPrice1))).to.equal(parseEther("0.999999999999999999"))
	// expect(parseEther(spearPrice1).add(parseEther(shieldPrice1))).to.equal(parseEther("1"))
	const status = await getBattleStatus(battle)
	console.log(status)
	return status
}

async function addLiquidity(battle: Battle, amount: number) { }
async function removeLiquidity(battle: Battle, amount: number) { }

describe("Creating Battle", () => {

	let arena: Arena
	let dai: MockToken
	let creater: Creater
	let oracle: Oracle
	let accounts: Signer[]

	before(async () => {
		if (process.env.ARENA === undefined) {
			console.error("arena env addr not exist")
			process.exit(1)
		} else {
			arena = (await attach("Arena", process.env.ARENA)) as Arena
		}

		if (process.env.DAI === undefined) {
			expect(process.env.DAI).to.exist
		} else {
			dai = (await attach("MockToken", process.env.DAI)) as MockToken
		}

		if (process.env.ORACLE === undefined) {
			expect(process.env.ORACLE).to.exist
		} else {
			oracle = (await attach("Oracle", process.env.ORACLE)) as Oracle
		}

		if (process.env.CREATER === undefined) {
			expect(process.env.CREATER).to.exist
		} else {
			creater = (await attach("Creater", process.env.CREATER)) as Creater
		}

		await dai.approve(arena.address, ethers.constants.MaxUint256)

		accounts = await ethers.getSigners()

	})

	describe("DAY Battle", () => {
		let battle: Battle

		beforeEach(async () => {
			const settleValue = (randomInt(80) / 100).toString()
			let tx = await arena.createBattle(dai.address, "BTC", ethers.utils.parseEther("10000"), parseEther("0.5"), parseEther("0.5"), 0, 0, parseEther(settleValue))
			await tx.wait()
			const battleNum = await arena.battleLength()
			expect(battleNum).to.equal(1)
			const battleAddr = await arena.getBattle(0)
			expect(battleAddr).to.exist
			battle = (await attach("Battle", battleAddr)) as Battle
			expect(battle.address).to.exist

			let tx1 = await dai.approve(battle.address, ethers.constants.MaxUint256)
			await tx1.wait()
		})

		afterEach(async () => {
			const battleAddr = await arena.getBattle(0)
			const tx = await arena.removeBattle(battleAddr)
			await tx.wait()

			// let now = new Date().getTime()
			// let ts = Math.floor(now / 1000)
			// await ethers.provider.send("evm_setNextBlockTimestamp", [ts])
			// await ethers.provider.send("evm_mine", [])
		})


		it("buy 100 spear, then buy 100 shield should work", async () => {
			await buySpear(battle, 100)
			await buyShield(battle, 100)
		})

		it("buy 100 shield, then buy 100 spear, should work", async () => {
			await buyShield(battle, 100)
			await buySpear(battle, 100)
		})

		it("buy 3000 spear then buy 4000 shield", async () => {
			await buySpear(battle, 3000)
			await buyShield(battle, 40)
		})

		// it("deployer buy spear and shield, then settle, then claim", async () => {
		// 	await buySpear(battle, 500)
		// 	await buyShield(battle, 600)
		// 	let now = new Date().getTime()
		// 	let ts = Math.floor(now / 1000) + 24 * 3600
		// 	await ethers.provider.send("evm_setNextBlockTimestamp", [ts])
		// 	await ethers.provider.send("evm_mine", [])

		// 	let b = await ethers.provider.getBlock("latest")
		// 	console.log(new Date(b.timestamp*1000))
		// 	const [start, end] = await oracle.getRoundTS(0)
		// 	console.log(`start: ${new Date(start.toNumber() * 1000).toJSON()}, end: ${new Date(end.toNumber() * 1000).toJSON()}`)
		// 	let txPrice = await oracle.setPrice("BTC", start, parseEther("100000"))
		// 	await txPrice.wait()
		// 	let txSettle = await battle.settle()
		// 	await txSettle.wait()

		// 	// claim
		// 	const {amount} = await battle.tryClaim(await accounts[0].getAddress())
		// 	console.log(formatEther(amount))
		// 	const txClaim = await battle.claim()
		// 	await txClaim.wait()

		// })

		it("user1 buy spear and shield, settle, claim", async () => {
			const user1Addr = await accounts[1].getAddress()
			await dai.transfer(user1Addr, parseEther("10000"))
			const daiUser1 = dai.connect(accounts[1])
			await daiUser1.approve(battle.address, ethers.constants.MaxUint256)

			const battleUser1 = battle.connect(accounts[1])
			await buySpear(battleUser1, 100)
			// await buyShield(battleUser1, 100)

			
			console.log('before settle userStatus', await getUserStatus(battle, dai, user1Addr))
			
			let now = new Date().getTime()
			let ts = Math.floor(now / 1000) + 24 * 3600
			await ethers.provider.send("evm_setNextBlockTimestamp", [ts])
			await ethers.provider.send("evm_mine", [])

			let b = await ethers.provider.getBlock("latest")
			console.log(new Date(b.timestamp*1000))
			const [start, end] = await oracle.getRoundTS(0)
			console.log(`start: ${new Date(start.toNumber() * 1000).toJSON()}, end: ${new Date(end.toNumber() * 1000).toJSON()}`)
			let txPrice = await oracle.setPrice("BTC", start, parseEther("100000"))
			await txPrice.wait()
			let txSettle = await battleUser1.settle()
			await txSettle.wait()
			expect(await battle.cri()).to.be.equal(start)

			// claim
			console.log('before claim userStatus', await getUserStatus(battle, dai, user1Addr))
			const {amount} = await battleUser1.tryClaim(user1Addr)
			console.log(formatEther(amount))
			const txClaim = await battleUser1.claim()
			await txClaim.wait()
			console.log('after claim userStatus', await getUserStatus(battle, dai, user1Addr))

		})

		it("buy 3000 dai spear, buy 199 dai shield, sell 1 shield", async () => {
			console.log("init status")
			console.log(await getBattleStatus(battle))
			console.log("after buy spear 3000 dai")
			await buySpear(battle, 3000)
			console.log("after buy shield 199 dai")
			await buyShield(battle, 199)
			console.log("after sell shield 1")
			await sellShield(battle, 1)
		})

		it("Buy 8000 dai spear, buy 1900 dai spear, sell 10 spear", async () => {
			console.log("after buy spear 5000 dai")
			await buySpear(battle, 5000)
			console.log("after buy shield 1900 dai")
			await buySpear(battle, 2900)
			console.log("sell 4000 spear")
			await sellSpear(battle, 4000)
			console.log("sell 2000 spear")
			await sellSpear(battle, 2000)

		})

		it("withdraw all liquidity", async () => {
			const status = await getBattleStatus(battle)
			console.log(status)
			const bal = await battle.balanceOf(await accounts[0].getAddress())
			console.log('user liqui bal', ethers.utils.formatEther(bal))
			await battle.removeLiquidity(bal, new Date().getTime())
			const statusAfter = await getBattleStatus(battle)
			console.log(statusAfter)

		})

		it("withdraw all liquidity after trading", async () => {
			const status = await getBattleStatus(battle)
			console.log(status)

			await battle.buySpear(parseEther("2000"), 0, 111111111111111)
			console.log('after trading')
			const statusAfterTrading = await getBattleStatus(battle)
			console.log(statusAfterTrading)


			const bal = await battle.balanceOf(await accounts[0].getAddress())
			console.log('user liqui bal', ethers.utils.formatEther(bal))
			await battle.removeLiquidity(bal, new Date().getTime())
			const statusAfter = await getBattleStatus(battle)
			console.log(statusAfter)

		})

	})

	describe("Create WEEK Battle", () => {

	})

	describe("Create MONTH Battle", () => {

	})
})