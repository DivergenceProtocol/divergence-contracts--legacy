import { expect, use } from "chai";
import {deploy} from "../scripts/utils";
import { Creater } from "../src/types";

// use('solidity')

describe("Deploy Creater", () => {
	let creater: Creater;

	before(async () => {
	    creater = (await deploy("Creater")) as Creater;
	    process.env.CREATER = creater.address
	})

	it("creater env address should not null", async () => {
		console.log(`creater addr ${process.env.CREATER}`)
		expect(process.env.CREATER).to.equal(creater.address)
	})
})
