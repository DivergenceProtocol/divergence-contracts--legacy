import { Signer } from "ethers";
import { ethers } from "hardhat";

describe("Token", function () {
	let accounts: Signer[];

	beforeEach(async function () {
	    accounts = await ethers.getSigners()	
	})

	it("should", async function () {
		console.log("should info test")	
	})
})