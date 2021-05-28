const { ethers } = require("hardhat")


describe("Battle2", function () {

    it("should create battle success", async ()=>{
        const Battle = await ethers.getContractFactory("Battle")
        const battle = await Battle.deploy()
        let collateral = "0x2e50131CD6E3A7736C68f1C530eF3bdFb068F619"
        let arena = "0x2e50131CD6E3A7736C68f1C530eF3bdFb068F619"
        let trackName = "wbtc"
        let priceName = "btc"
        let 

        await battle.init0()
        await battle.init()
    })
})