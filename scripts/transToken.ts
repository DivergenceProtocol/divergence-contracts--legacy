const { ethers } = require("hardhat")
const {deploy, transferMulti} = require("./utils")
const {diverAddr, usdcAddr, DAI} = require("../contracts.json")
async function transferToken() {
	let addrs = ["0xCE8dDfCF89c1474251BBDf612462983B351B9876", "0x2f33a1EBAc1F8FF0341404C8330CB5f9798F63e1", "0xfc4676788604e7Fb25549a754C3c14f0160969ba", "0x08Aae95AC975CDa10f3aF24f2B5A0616aDbA68F5", "0x1415F60Be6063917b2bA798ba5Ae9ceA63381CBF"]
	// let addrs = ["0x08Aae95AC975CDa10f3aF24f2B5A0616aDbA68F5", "0xCE8dDfCF89c1474251BBDf612462983B351B9876", "0x5D874e9b82A2c4984e3E520C927c8D19E8F70398", "0x5D874e9b82A2c4984e3E520C927c8D19E8F70398"]
	// let addrs = ["0x2f33a1EBAc1F8FF0341404C8330CB5f9798F63e1", "0x11d531de5f6c7EE6a1F1E125dbdf1996235f91B9"]
	// let addrs = ["0x1415F60Be6063917b2bA798ba5Ae9ceA63381CBF"]
	// await transferMulti("Diver", diverAddr, addrs, ethers.utils.parseEther("30000000"))
	await transferMulti("MockToken", process.env.MT_USDC, addrs, ethers.utils.parseUnits("1000000", 6))
	await transferMulti("MockToken", process.env.MT_DAI, addrs, ethers.utils.parseUnits("1000000", 18))
	await transferMulti("MockToken", process.env.MT_WETH, addrs, ethers.utils.parseUnits("1000000", 18))
	await transferMulti("MockToken", process.env.MT_WBTC, addrs, ethers.utils.parseUnits("1000000", 8))
}

async function main() {
	await transferToken()
}

main().then(() => {
	process.exit(0)
}).catch(err => {
	console.log(err)
	process.exit(1)
})