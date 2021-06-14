const { parseEther } = require("@ethersproject/units");
const { expect } = require("chai");
const {deployProxy, deploy} = require("../scripts/utils")
const {ethers} = require("ethers")

describe("Oracle", function () {

    before(async () => {
        let oracle = await deployProxy("Oracle")
        this.oracle = oracle
    })

    it('set month ts', async () => {
        console.log(`oracle ${this.oracle.address}`)
    })

})