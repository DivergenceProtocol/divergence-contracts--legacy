import { ethers, network} from "hardhat";
import { Arena } from "../src/types";
import { attach, deploy } from "./utils";


async function main() {
	// get all battle address
	let arena = await attach<Arena>("Arena", "0xdd4cD9ce6710ccAAd8efbEae0Be8aEe053cd92c8")
	let lens = await arena.battleLength()
	let length = Number(ethers.utils.formatUnits(lens, 0))
	console.log("battle len", length)
	let addrs: string[] = []
	for (let i=0; i < length; i++) {
	// for (let i=0; i < 3; i++) {
		// console.log(i)
		let battleAddr = await arena.getBattle(i)
		console.log(battleAddr.toLowerCase())
		addrs.push(battleAddr.toLowerCase())
	}
	console.log(addrs)
	// get transaction from 
	let [sender] = await ethers.getSigners()
	let provider = sender.provider!
	for (let i=27553216+7200; i < 27563216 ; i++) {
		console.log(27563216-i)
		let block = await provider.getBlockWithTransactions(i)
		let transactions = block.transactions
		for (const tx of transactions) {
			if (tx.to === null ) {
				continue
			} else {
				console.log(tx.to)
				if (tx.to!.toLowerCase() in addrs) {
					console.log(tx.hash)
					break
				}
			}
		}
	}
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });