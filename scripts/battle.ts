import { Signer } from "ethers";
import { ethers } from "hardhat";
import { Battle } from "../src/types/Battle"
import { getUserStatus } from "./utils";

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
	// await battlePrice()
	const accounts = await ethers.getSigners()
	await claim("0xacF5cE78bA726Ba4276daEeB324DF905Ecd75D48", accounts[0])
}

async function setttleBattle() {
	const battle = await ethers.getContractAt("Battle", "0x117f03Fcd76aa670129E5A5bc1F18A9Cb8D4CbD2")
	await battle.settle()
}

async function battlePrice() {
	const battle = await ethers.getContractAt("Battle", "0x74686E2d19b7568EA05960bf92Cb840C971D1670")
	const cri = await battle.cri()
	const spearPrice = await battle.spearPrice(cri)
	const shieldPrice = await battle.shieldPrice(cri)
	console.log(`spear price ${ethers.utils.formatEther(spearPrice)}`)
	console.log(`shield price ${ethers.utils.formatEther(shieldPrice)}`)
}

async function claim(battleAddr: string, signer: Signer) {
	// console.log(await getUserStatus())
	const battle = await ethers.getContractAt("Battle", battleAddr)
	const amount =  await battle.tryClaim(await signer.getAddress())
	console.log(`try claim amount ${amount}`)
	const battleSigner = battle.connect(signer)
	let tx = await battleSigner.claim()
	await tx.wait()
}

main().then(() => {
	process.exit(0)
}).catch(err => {
	console.log(err)
	process.exit(1)
})