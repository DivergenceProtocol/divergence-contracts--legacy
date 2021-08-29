import { formatUnits } from "@ethersproject/units";
import { Sign } from "crypto";
import { Signer } from "ethers";
import { ethers } from "hardhat";
import { Arena, MockToken } from "../src/types";
import { Battle } from "../src/types/Battle"
import { getUserStatus } from "./utils";

const {deploy, transferMulti} = require("./utils")
const {diverAddr, usdcAddr} = require("../contracts.json")
const { formatEther } = require("ethers/lib/utils")

async function main() {

	const accounts = await ethers.getSigners()
	const first = await accounts[0].getAddress()
	// // const battle = await ethers.getContractAt("Battle", "0x1af9bc642BC941Ff974726d1a0348afCb95c6Ec7")
	// const battle = await ethers.getContractAt("Battle", "0xD409F17ec793d3854Cf29D0eb75a7c65ab4B16FF")
	// // const amount = await battle.tryClaim("0x466043D6644886468E8E0ff36dfAF0060aEE7d37")
	// // console.log(`amount ${amount}`)
	// // const ri = await battle.enterRoundId("0x466043D6644886468E8E0ff36dfAF0060aEE7d37")
	// // console.log(`ri ${ri}`)
	// let account = "0x5D874e9b82A2c4984e3E520C927c8D19E8F70398"
	// const [ris] = await battle.expiryExitRis(account)
	// console.log(ris)
	// const cri = await battle.cri()
	// const lp = await battle.removeAppointment(cri, "0x5D874e9b82A2c4984e3E520C927c8D19E8F70398")
	// console.log(formatEther(lp))
	// await setttleBattle()
	// await battlePrice()
	// const accounts = await ethers.getSigners()
	// await claim("0xacF5cE78bA726Ba4276daEeB324DF905Ecd75D48", accounts[0])

	// await tryAddLiquidity("0x0c8137c270f2b819fe4C9082D182586Af03be805", accounts[0])

	// const battleAddr = "0xe5982beefc0dD5988121C9b4293880529ce8D420"
	// const battleAddr = "0xe5982beefc0dD5988121C9b4293880529ce8D420"
	// await claim(battleAddr, accounts[0])
	// await withdrawLiquidityHistory(battleAddr, accounts[0])

	// await value(battleAddr, accounts[0])

	// await battlePrice()
	// await caluculateLPValue('0x501BB047A9F5646f84f86B88D10B9AabCd40eCB0')

	// await claimedEvent('0x150bfafe14ab548d012b4f9c91e75e5290f7af38')
	// await tyWithdrawLiquidityHistory('0xcA9C31699b965Ca8cB74E3e896e8c1774047D67e', '0x5D874e9b82A2c4984e3E520C927c8D19E8F70398')
	await claimedEvent('0x03CCa967FEc8587faa6D57903db6A322B763ca1E')
}

async function setttleBattle() {
	const battle = await ethers.getContractAt("Battle", "0x117f03Fcd76aa670129E5A5bc1F18A9Cb8D4CbD2")
	await battle.settle()
}

async function battlePrice() {
	const battle = await ethers.getContractAt("Battle", "0x66597d6364e405e93903443cad502fafa40ffa9b") as Battle
	const cri = await battle.cri()
	const spearPrice = await battle.spearPrice(cri)
	const shieldPrice = await battle.shieldPrice(cri)
	console.log(`spear price ${ethers.utils.formatEther(spearPrice)}`)
	console.log(`shield price ${ethers.utils.formatEther(shieldPrice)}`)
	let {strikePriceOver} = await battle.getCurrentRoundInfo()
	console.log(formatEther(strikePriceOver))
}

async function claim(battleAddr: string, signer: Signer) {
	// console.log(await getUserStatus())
	const battle = await ethers.getContractAt("Battle", battleAddr)
	const amount =  await battle.tryClaim(await signer.getAddress())
	console.log(`try claim amount ${amount}`)
	// const battleSigner = battle.connect(signer)
	// let tx = await battleSigner.claim()
	// await tx.wait()
}

async function tryAddLiquidity(battleAddr: string, signer: Signer) {
	const userAddr = await signer.getAddress()
	const battle = await ethers.getContractAt("Battle", battleAddr) as Battle
	const result = await battle.tryAddLiquidity(1000000)
	console.log("try add 1 usdc liquidity")
	console.log("deltaSpear", formatEther(result.deltaSpear))
	console.log("deltaShield", formatEther(result.deltaShield))
	const userBalance = battle.balanceOf(userAddr)
	console.log("user balance", formatEther(userBalance))
}

async function tyWithdrawLiquidityHistory(battleAddr: string, userAddr: string) {
	const battle = await ethers.getContractAt("Battle", battleAddr) as Battle
	const amount = await battle.tryWithdrawLiquidityHistory(userAddr)
	console.log(`withdraw liquidity ${amount}`)
}

async function value(battleAddr: string, signer: Signer) {
	const battle = await ethers.getContractAt("Battle", battleAddr) as Battle
	const total = await battle.totalSupply()
	// const bal = await battle.balanceOf('0xCE8dDfCF89c1474251BBDf612462983B351B9876')
	const bal = await battle.balanceOf('0x82C350e3B7A05cd72C9169A3f048FEC42D7C074a')
	const collateralToken = await ethers.getContractAt("MockToken", "0x2e4c42c0ea662a87362e7dca09842e58e14038f2") as MockToken
	const mockBal = await collateralToken.balanceOf(battleAddr)
	const value = bal.div(total).mul(mockBal)
	console.log(`bal ${ethers.utils.formatEther(bal)} total ${ethers.utils.formatEther(total)} mockBal ${ethers.utils.formatEther(mockBal)}`)
	console.log(`${bal.div(total)}`)
	console.log(`value is ${ethers.utils.formatEther(value)}`)

}

async function caluculateLPValue(battleAddr: string) {
	const battle = await ethers.getContractAt("Battle", battleAddr) as Battle
	let cri = await battle.cri()
	let cAmount = await battle.collateral(cri)
	let lpTotal = await battle.totalSupply()
	console.log(`cAmount ${formatEther(cAmount)}, lpTotal ${formatEther(lpTotal)}`)
}

async function claimedEvent(arenaAddr: string) {
	const arena = await ethers.getContractAt("Arena", arenaAddr) as Arena
	let battleLen = Number(formatUnits(await arena.battleLength(), '0'))
	for (let i=0; i < battleLen; i++) {
		let battleAddr = await arena.getBattle(i)	
		const battle = await ethers.getContractAt("Battle", battleAddr) as Battle
		let f = battle.filters.Claimed(null, null, null, null)
		let result = await battle.queryFilter(f, 26955491, 'latest')
		console.log(result)
	}
	
}

main().then(() => {
	process.exit(0)
}).catch(err => {
	console.log(err)
	process.exit(1)
})