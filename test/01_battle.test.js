const { parseEther, formatEther } = require("@ethersproject/units");
const { expect } = require("chai");
const {deployProxy, deploy, attach} = require("../scripts/utils")
const {ethers} = require("hardhat")

async function balance(contractAddr, account) {
    const token = await attach("MockToken", contractAddr)
    const balance =await token.balanceOf(account)
    const bal = formatEther(balance)
    console.log(`token ${contractAddr} balanceOf ${account}: ${bal}`)
}

async function allowance(contractAddr, owner, spender) {
    const token = await attach("MockToken", contractAddr)
    const balance =await token.allowance(owner, spender)
    const bal = formatEther(balance)
    console.log(`token ${contractAddr} owner ${owner} allown ${spender}: ${bal}`)
}


describe("Battle2", function () {

    // let arena;
    let multicall;

    before(async () => {
        let creater = await deploy("Creater")
        this.creater = creater
        let oracleAddr = process.env.ORACLE
        console.log(`oracle ${oracleAddr} in battle`)
        let arena = await deployProxy("Arena", this.creater.address, oracleAddr)
        this.arena = arena
        let dai = await deploy("MockToken", "DAI", "DAI", 18)
        this.dai = dai



        const [deployer, feeto, user1, user2, user3] = await ethers.getSigners()
        console.log(`deploy : ${deployer.address}, feeto : ${feeto.address}`)
        this.feeto = feeto.address
        this.deployer = deployer.address
        this.user1 = user1
        this.user2 = user2
        this.user3 = user3

    })

    it("Add underlying", async () => {
        let tx = await this.arena.setUnderlying('BTC', true)
        await tx.wait()
        let result = await this.arena.underlyingList('BTC')
        expect(result).to.equal(true)
    })

    it("Set Creater", async () => {
        let txSetCreater = await this.arena.setCreater(this.creater.address)
        await txSetCreater.wait()
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

    it('Set Battle', async () => {
        let battleAddr = await this.arena.getBattle(0)
        const battle = await attach("Battle", battleAddr)
        this.battle = battle

        let tx = await this.arena.setBattleFeeTo(this.battle.address, this.feeto)
        await tx.wait()
        let txFeeRatio = await this.arena.setBattleFeeRatio(this.battle.address, parseEther("0.001"))
        await txFeeRatio.wait()

        let cri = await this.battle.cri()
        this.cri = cri;
    })

    it("Buy Spear", async () => {
        let txApprove = await this.dai.approve(this.battle.address, ethers.constants.MaxUint256)
        await txApprove.wait()
        const spearWillGet = await this.battle.tryBuySpear(parseEther("1000"))
        expect(spearWillGet).to.equal(parseEther("2000"))
        let txBuySpear = await this.battle.buySpear(parseEther("1000"))
        await txBuySpear.wait()

    })

    it("Buy Shield", async () => {
        // let txApprove = await this.dai.approve(this.battle.address, ethers.constants.MaxUint256)
        // await txApprove.wait()
        const shieldWillGet = await this.battle.tryBuyShield(parseEther("1000"))
        console.log(`shieldWillGet ${formatEther(shieldWillGet)}`)
        let txBuyShield = await this.battle.buyShield(parseEther("1000"))
        await txBuyShield.wait()
    })

    it("Sell Spear", async () => {
        const spearBalance = await this.battle.spearBalance(this.cri, this.deployer)
        const collateralWillGet = await this.battle.trySellSpear(spearBalance.div(2))
        console.log(`collateralWillGet ${formatEther(collateralWillGet)}`)
        let tx = await this.battle.sellSpear(spearBalance.div(2))
        await tx.wait()
    })

    it("Sell Shield", async () => {
        const shieldBalance = await this.battle.shieldBalance(this.cri, this.deployer)
        const collateralWillGet = await this.battle.trySellShield(shieldBalance.div(3))
        console.log(`collateralWillGet ${formatEther(collateralWillGet)}`)
        let tx = await this.battle.sellShield(shieldBalance.div(3))
        await tx.wait()
    })

    it("Add Liqui", async () => {
        const {cDeltaSpear, cDeltaShield, deltaSpear, deltaShield, lpDelta} = await this.battle.tryAddLiquidity(parseEther("1000"))
        const tx = await this.battle.addLiquidity(parseEther("1000"))
        await tx.wait()
    })

    it("Remove Liqui", async () => {
        const {cDeltaSpear, cDeltaShield, deltaSpear, deltaShield, lpDelta} = await this.battle.tryRemoveLiquidity(parseEther("500"))
        const tx = await this.battle.removeLiquidity(parseEther("500"))
        await tx.wait()
    })

    it("Remove Liqui Future", async () => {
        let txApprove = await this.battle.approve(this.battle.address, ethers.constants.MaxUint256)
        await txApprove.wait()
        let allow = await this.battle.allowance(this.deployer, this.battle.address)
        await allowance(this.battle.address, this.deployer, this.battle.address)
        await balance(this.battle.address, this.deployer)
        let tx =await this.battle.removeLiquidityFuture(parseEther("200"))
        await tx.wait()
    })

    it("Set Next Round Spear Price", async () => {
        let tx = await this.battle.setNextRoundSpearPrice(parseEther("0.44"))
        await tx.wait()
    })
})