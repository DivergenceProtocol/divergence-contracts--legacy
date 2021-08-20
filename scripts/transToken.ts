import { parseEther } from "@ethersproject/units"

const { ethers } = require("hardhat")
const {deploy, transferMulti} = require("./utils")
const {diverAddr, usdcAddr, DAI} = require("../contracts.json")

const earlyUsers = [
'0x99BC02c239025E431D5741cC1DbA8CE77fc51CE3',
'0xf64bE5469e7EF79bD27b835B8eF8CB2196aDF4C3',
'0x958D794ab63AD6d0B69A2Fb5298d955DA8eE095E',
'0x00777f6f80c30c9DdE6ec8547eac99756837C3E3',
'0x109ad7d9b0738bb5B6a0679740649B66097a1E74',
'0xb2f6129b4B2fa2061BBf6d136BEE016A66D821Fb',
'0x1609b4E06392893CF5da0C5f5c0593937838De75',
'0xd13BFC21a3a5597ace212B0beD7F654101B66253',
'0xAe15a8f0DB29c6C7a840aBc445ABE3CD3B0af472',
'0x1aC5d648599B9767b1a1bd13eB8BF082B4C157c2',
'0x56b310963dDa3794B5162CedBEfE56E99E23f8ce',
'0x3185EF019BA1C04B8d65eDB64c1c34C3eaE52271',
'0xaF497FF72118d885deFf61364d58De155f544751',
'0x654750C0643097E242651270136e9fF8343e89d1',
'0x41797b5e0398aF475422f6F33F2dc81d9a24aE33',
'0x1B3118B404b681D9e828e9C52a54a3a2ccDf727f',
'0x7BAFC0D5c5892f2041FD9F2415A7611042218e22',
'0xf0d66807004b4080E02026b50DA1d3b214d2b4b6',
'0x2b47C57A4c9Fc1649B43500f4c0cDa6cF29be278',
'0x63d5BDee0d0D427E76EB36CFF39D188FEd48FDf7',
'0x27CA52818a435fd3A949fbB4CE7aaCb8Ce19d4d6',
'0x8C82219D15FA8736a393bee84Fb3A4e56727163e',
'0xE9E6FbB1cCe0b06B139aBcC1122B31a530161B28',
'0xe1e3c181d73ecfd603ae59bc2f71752a4d9a5cf5',
'0x695d9D403ecC4EDAE49fe0DB842b898793a06b4a',
'0x7e6693c71D60CAe4DBcf583679F3616A19323834',
'0x03D70d5aC20FCa03050427C99a9097874b3cdC16',
'0x29E93c9648386283012a5444E1bF63613e789332',
'0x4086E0e1B3351D2168B74E7A61C0844b78f765F2',
'0xD7f12eB2D95726B5553b3edB69F38BBc4b096fa8',
'0x8aEe10A3e0ef4bF2dBD3a050ECF392A136E29067',
]

async function transferETH(users: string[]) {
	const deployer = (await ethers.getSigners())[0]
	for (let i=0; i<users.length; i++) {
		let tx = await deployer.sendTransaction({to:users[i], value: parseEther('0.1')})
		await tx.wait()
	}
}

async function transferToken(users: string[]) {
	// let addrs = ["0xCE8dDfCF89c1474251BBDf612462983B351B9876", "0x2f33a1EBAc1F8FF0341404C8330CB5f9798F63e1", "0xfc4676788604e7Fb25549a754C3c14f0160969ba", "0x08Aae95AC975CDa10f3aF24f2B5A0616aDbA68F5", "0x1415F60Be6063917b2bA798ba5Ae9ceA63381CBF"]
	// let addrs = ["0x08Aae95AC975CDa10f3aF24f2B5A0616aDbA68F5", "0xCE8dDfCF89c1474251BBDf612462983B351B9876", "0x5D874e9b82A2c4984e3E520C927c8D19E8F70398", "0x5D874e9b82A2c4984e3E520C927c8D19E8F70398"]
	// let addrs = ["0x2f33a1EBAc1F8FF0341404C8330CB5f9798F63e1", "0x11d531de5f6c7EE6a1F1E125dbdf1996235f91B9"]
	// let addrs = ["0x1415F60Be6063917b2bA798ba5Ae9ceA63381CBF"]
	// await transferMulti("Diver", diverAddr, addrs, ethers.utils.parseEther("30000000"))
	// let addrs = ["0x334bBDeAC624A1FA906689101179A9b98510B0EB"]
	await transferMulti("MockToken", process.env.MT_USDC, users, ethers.utils.parseUnits("10000", 6))
	await transferMulti("MockToken", process.env.MT_DAI, users, ethers.utils.parseUnits("10000", 18))
	await transferMulti("MockToken", process.env.MT_WETH, users, ethers.utils.parseUnits("5", 18))
	await transferMulti("MockToken", process.env.MT_WBTC, users, ethers.utils.parseUnits("3", 8))
}

async function main() {
	await transferToken(earlyUsers)
	// await transferETH(earlyUsers)
}

main().then(() => {
	process.exit(0)
}).catch(err => {
	console.log(err)
	process.exit(1)
})