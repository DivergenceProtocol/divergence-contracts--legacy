const { ethers } = require("hardhat")
const {deploy, transferMulti} = require("./utils")
const {diverAddr, usdcAddr} = require("../contracts.json")
async function transferToken() {
	let addrs = ["0xCE8dDfCF89c1474251BBDf612462983B351B9876", "0x2f33a1EBAc1F8FF0341404C8330CB5f9798F63e1"]
	await transferMulti("Diver", diverAddr, addrs, ethers.utils.parseEther("30000000"))
	await transferMulti("MockToken", usdcAddr, addrs, ethers.utils.parseUnits("1000000", 6))
}

async function main() {
	// const diver = await deploy("Diver")	
	// console.log(`deploy diver at ${diver.address}`)
	// const usdc = await deploy("MockToken", "USD Coin", "USDC", 6)
	// console.log(`deploy usdc at ${usdc.address}`)
	await transferToken()
}

main().then(() => {
	process.exit(0)
}).catch(err => {
	console.log(err)
	process.exit(1)
})