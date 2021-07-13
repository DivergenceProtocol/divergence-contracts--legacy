const { ethers } = require("hardhat")
const {deploy, transferMulti} = require("./utils")
const {diverAddr, usdcAddr} = require("../contracts.json")
const { formatEther } = require("ethers/lib/utils")

async function main() {
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
	await battlePrice()
}

async function setttleBattle() {
	const battle = await ethers.getContractAt("Battle", "0x117f03Fcd76aa670129E5A5bc1F18A9Cb8D4CbD2")
	await battle.settle()
}

async function battlePrice() {
	const battle = await ethers.getContractAt("Battle", "0x10C9cb49160754a2266DE6891100CB5219594C1D")
	const cri = await battle.cri()
	const spearPrice = await battle.spearPrice(cri)
	const shieldPrice = await battle.shieldPrice(cri)
	console.log(`spear price ${ethers.utils.formatEther(spearPrice)}`)
	console.log(`shield price ${ethers.utils.formatEther(shieldPrice)}`)
}

main().then(() => {
	process.exit(0)
}).catch(err => {
	console.log(err)
	process.exit(1)
})