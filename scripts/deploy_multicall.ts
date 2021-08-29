
import { Battle, DMulticall, ERC20, Multicall} from '../src/types';
import { deploy } from './utils'
require('dotenv').config()

import * as cons from "../contracts.json"
import { ethers } from 'hardhat';

let multicallAddr='';
switch (process.env.TEST_VERSION) {
	case 'BETA':
		multicallAddr = cons.BETA.DMulticall
		break
	default:
		console.error("not found version")
}

async function main() {
	// let battleAddrs: string[] = ['0xd716d25349d5516304cddbd7b88b92769db08dec', '0xa1Aca81B0d13A9EA4824a8db66eEfd8E66874Ec2']
	// let tokenAddr: string[] = ['0x2e4c42c0ea662a87362e7dCa09842e58E14038F2', '0xD5A0E9F817373f1Cf28Ef680d15BB981fEDF83cb']
	// battleAddrs.map(async (addr) => {
	// 	let bal = await ethers.getContractAt('Battle', 'addr') as Battle
	// 	// bal.interface.encodeFunctionData()
	// 	return bal
	// })

	// let calldatas: string[] = [] 
	// let targets: string[] = []
	// for (const addr of battleAddrs) {
	// 	let bal = await ethers.getContractAt('Battle', addr) as Battle
	// 	// let cir = await bal.cri().
	// 	// let re = await bal.getCurrentRoundInfo()
	// 	let re = await bal.callStatic.getCurrentRoundInfo()
	// 	console.log(re)
	// 	let calldata = bal.interface.encodeFunctionData('getCurrentRoundInfo')
	// 	console.log(calldata, bal.address)
	// 	targets.push(bal.address)
	// 	calldatas.push(calldata)
	// }
	// let mc = await getMulticall()
	// let result = await mc.callStatic.multicall(targets, calldatas)
	// console.log(result)
	// let battle = await ethers.getContractAt('Battle', '0xd716d25349d5516304cddbd7b88b92769db08dec')
	// for (const d of result) {
	// 	let r = battle.interface.decodeFunctionResult('cri', d)
	// 	console.log('result', r)
	// }
	// let result = await mc.multicall(calldatas)
	let mc = await getMulticall()
	// await erc20Multi(mc)
	await mcCall(mc)
}

async function erc20Multi(mc: Multicall) {
	// let user = '0x466043D6644886468E8E0ff36dfAF0060aEE7d37'
	// let erc20Addrs = ['0x2e4c42c0ea662a87362e7dCa09842e58E14038F2', '0xD5A0E9F817373f1Cf28Ef680d15BB981fEDF83cb']
	// let calldatas = await Promise.all(erc20Addrs.map(async (addr) => {
	// 	let t = await ethers.getContractAt('ERC20', addr) as ERC20
	// 	let balance = await t.balanceOf(user)
	// 	console.log(balance)
	// 	let calldata = t.interface.encodeFunctionData('balanceOf', [user])
	// 	return calldata
	// }))
	// console.log(calldatas)
	// let result = await mc.callStatic.multicall(erc20Addrs, calldatas)
	// console.log(result)
	
}

async function mcCall(mc: Multicall) {

	let d1 = mc.interface.encodeFunctionData('name1')
	let d2 = mc.interface.encodeFunctionData('name2')
	let result = await mc.callStatic.multicall([d1, d2])
	console.log(result)
	
}


async function getMulticall(): Promise<DMulticall> {
	if (multicallAddr === '') {
		return await deploy('DMulticall') as DMulticall
	} else {
		const [s] = await ethers.getSigners()
		console.log(`signer is ${await s.getAddress()}`)
		return await ethers.getContractAt('DMulticall', multicallAddr, s) as DMulticall
	}
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	})