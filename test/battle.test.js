const { parseEther } = require("@ethersproject/units");
const { expect } = require("chai");
const {deployProxy, deploy, attach} = require("../scripts/utils")
const {ethers} = require("ethers")


describe("Battle2", function () {

    // let arena;
    let multicall;

    before(async () => {
        let arena = await deployProxy("Arena", "0x809d550fca64d94Bd9F66E60752A544199cfAC3D")
        this.arena = arena
        let dai = await deploy("MockToken", "DAI", "DAI", 18)
        this.dai = dai

        let creater = await deploy("Creater")
        this.creater = creater

        let txSetCreater = await this.arena.setCreater(this.creater.address)
        await txSetCreater.wait()

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
        let battleLen = await this.arena.battleLength()
        expect(battleLen).to.equal(1)
    })

    it("Buy Spear", async () => {
        let battleAddr = await this.arena.getBattle(0)
        let txApprove = await this.dai.approve(battleAddr, ethers.constants.MaxUint256)
        await txApprove.wait()
        const battle = await attach("Battle", battleAddr)
        const spearWillGet = await battle.tryBuySpear(parseEther("1000"))
        expect(spearWillGet).to.equal(parseEther("2000"))
        let txBuySpear = await battle.buySpear(parseEther("1000"))
        await txBuySpear.wait()

    })
})