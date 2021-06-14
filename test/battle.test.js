const { parseEther } = require("@ethersproject/units");
const { expect } = require("chai");
const {deployProxy, deploy} = require("../scripts/utils")
const {ethers} = require("ethers")


describe("Battle2", function () {

    // let arena;
    let multicall;

    before(async () => {
        let arena = await deployProxy("Arena", "0x809d550fca64d94Bd9F66E60752A544199cfAC3D")
        this.arena = arena
        let dai = await deploy("MockToken", "DAI", "DAI", 18)
        this.dai = dai
    })

    it("Add underlying", async () => {
        let tx = await this.arena.setUnderlying('BTC', true)
        await tx.wait()
        let result = await this.arena.underlyingList('BTC')
        expect(result).to.equal(true)
    })

    it('Create Battle', async () => {
        let tx = await this.dai.approve(this.arena.address, ethers.constants.MaxUint256)
        await tx.wait()
        let txCreateBattle = await this.arena.createBattle(this.dai.address, 'BTC', parseEther("10000"), parseEther("0.4"), parseEther("0.6"), 0, 1, parseEther("0.03"))
        console.log(`crateBattle pending tx ${txCreateBattle.hash}`)
        await txCreateBattle.wait()
        // let battleLen = await this.arena.battleLength()
        // expect(battleLen).to.equal(1)
    })

    // it("should create battle success", async ()=>{
        // const Battle = await ethers.getContractFactory("Battle")
    //     const battle = await Battle.deploy()
    //     let collateral = "0x2e50131CD6E3A7736C68f1C530eF3bdFb068F619"
    //     let trackName = "wbtc"
    //     let priceName = "btc"

    //     await battle.init0()
    //     await battle.init()
    // })

    // it("Should get battle info", async () => {
    //     let battle_addr = await this.arena.getBattle(0)
    //     console.log(battle_addr)
    //     // battle = await ethers.getContractAt("Battle", battle_addr)
    //     // const battle_info = await battle.getBattleInfo()
    //     // console.log(battle_info)
    // })
})