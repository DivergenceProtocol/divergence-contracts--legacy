const { parseEther, formatEther, formatUnits} = require("@ethersproject/units");
const { expect } = require("chai");
const {deployProxy, deploy, attach} = require("../scripts/utils")
const {ethers, network} = require("hardhat");
const { utils } = require("ethers");

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

async function getPriceStatus(battle, ri) {
    // expect(await battle.spearBalance(this.cri, this.deployer.address)).to.equal(spearWillGet)
    let spearPriceAfter = await battle.spearPrice(ri)
    console.log(`spear price after %s`, formatEther(spearPriceAfter))
    // expect(spearPriceAfter).to.closeTo(parseEther("0.882"), parseEther("0.001"))
    let shieldPriceAfter = await battle.shieldPrice(ri)
    console.log(`shield price after %s`, formatEther(shieldPriceAfter))
    // expect(shieldPriceAfter).to.closeTo(parseEther("0.118"), parseEther("0.001"))
}

async function getBondingCurveStatus(battle, ri) {
    let spearAmount = await battle.spearBalance(ri, battle.address)
    let cSpear = await battle.cSpear(ri)
    let shieldAmount = await battle.shieldBalance(ri, battle.address)
    let cShield = await battle.cShield(ri)
    console.log(`Spear Amount ${formatEther(spearAmount)}, Collateral spear ${formatEther(cSpear)}`)
    console.log(`Shield Amount ${formatEther(shieldAmount)}, Collateral shield ${formatEther(cShield)}`)
}


describe("Battle2", function () {

    // let arena;
    let multicall;

    before(async () => {
        let creater = await deploy("Creater")
        this.creater = creater
        let oracleAddr = process.env.ORACLE
        console.log(`oracle ${oracleAddr} in battle`)
        this.oracle = await attach("Oracle", oracleAddr)
        let arena = await deployProxy("Arena", this.creater.address, oracleAddr)
        this.arena = arena
        let dai = await deploy("MockToken", "DAI", "DAI", 18)
        this.dai = dai



        const [deployer, user1, feeto, user2, user3] = await ethers.getSigners()
        console.log(`deploy : ${deployer.address}, feeto : ${feeto.address}`)
        this.feeto = feeto.address
        this.deployer = deployer
        this.user1 = user1
        this.user2 = user2
        this.user3 = user3

        this.initLP = "10000"
        this.initSpearPrice = "0.5"
        this.initShieldPrice = "0.5"
        this.feeRatio = "0.03"

        await this.dai.transfer(user1.address, parseEther("10000000"))

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
        let txCreateBattle = await this.arena.createBattle(this.dai.address, 'BTC', parseEther(this.initLP), parseEther(this.initSpearPrice), parseEther(this.initShieldPrice), 0, 1, parseEther("0.03"))
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
        let txFeeRatio = await this.arena.setBattleFeeRatio(this.battle.address, parseEther(this.feeRatio))
        await txFeeRatio.wait()

        let cri = await this.battle.cri()
        this.cri = cri;
    })

    it("Buy Spear", async () => {
        let battleOfUser = this.battle.connect(this.user1)
        let daiOfUser = this.dai.connect(this.user1)

        let txApprove = await daiOfUser.approve(battleOfUser.address, ethers.constants.MaxUint256)
        await txApprove.wait()
        const spearWillGet = await battleOfUser.tryBuySpear(parseEther("20"))
        // expect(spearWillGet).to.equal(parseEther())
        console.log(`spear will get ${formatEther(spearWillGet)}`)
        // expect(spearWillGet).to.closeTo(parseEther("23.81"), parseEther("0.01"))
        let txBuySpear = await battleOfUser.buySpear(parseEther("20"), spearWillGet, Math.floor(new Date().getTime()/1000)+300)
        await txBuySpear.wait()
        // expect(await battleOfUser.spearBalance(this.cri, this.deployer.address)).to.equal(spearWillGet)
        let spearPriceAfter = await battleOfUser.spearPrice(this.cri)
        console.log(`spear price after %s`, formatEther(spearPriceAfter))
        // expect(spearPriceAfter).to.closeTo(parseEther("0.882"), parseEther("0.001"))
        let shieldPriceAfter = await battleOfUser.shieldPrice(this.cri)
        console.log(`shield price after %s`, formatEther(shieldPriceAfter))
        // expect(shieldPriceAfter).to.closeTo(parseEther("0.118"), parseEther("0.001"))

    })

    it("Buy Shield", async () => {
        let battleOfUser = this.battle.connect(this.user1)
        let daiOfUser = this.dai.connect(this.user1)
        let txApprove = await daiOfUser.approve(this.battle.address, ethers.constants.MaxUint256)
        await txApprove.wait()
        const shieldWillGet = await battleOfUser.tryBuyShield(parseEther("100"))
        console.log(`shieldWillGet ${formatEther(shieldWillGet)}`)
        let txBuyShield = await battleOfUser.buyShield(parseEther("100"), shieldWillGet, Math.floor(new Date().getTime()/1000)+300)
        await txBuyShield.wait()
        await getPriceStatus(this.battle, this.cri)
    })

    it("Sell Spear", async () => {
        await getBondingCurveStatus(this.battle, this.cri)
        const spearBalance = await this.battle.spearBalance(this.cri, this.deployer.address)
        console.log(`Sell Spear ${formatEther(spearBalance.div(2))}`, )
        const collateralWillGet = await this.battle.trySellSpear(spearBalance.div(2))
        console.log(`collateralWillGet ${formatEther(collateralWillGet)}`)
        let tx = await this.battle.sellSpear(spearBalance.div(2), collateralWillGet, Math.floor(new Date().getTime()/1000)+300)
        await tx.wait()
        await getBondingCurveStatus(this.battle, this.cri)
    })

    it("Sell Shield", async () => {
        await getBondingCurveStatus(this.battle, this.cri)
        const shieldBalance = await this.battle.shieldBalance(this.cri, this.deployer.address)
        const collateralWillGet = await this.battle.trySellShield(shieldBalance.div(3))
        console.log(`collateralWillGet ${formatEther(collateralWillGet)}`)
        let tx = await this.battle.sellShield(shieldBalance.div(3), collateralWillGet, Math.floor(new Date().getTime()/1000)+300)
        await tx.wait()
        await getBondingCurveStatus(this.battle, this.cri)
    })

    it("setNextRoundSpearPrice", async () => {
        const spearStartPriceBefore = await this.battle.spearStartPrice()
        console.log(`spear start price before ${ethers.utils.formatEther(spearStartPriceBefore)}`)
        await this.battle.setNextRoundSpearPrice(ethers.utils.parseEther("0.22"))
        const spearStartPriceAfter = await this.battle.spearStartPrice()
        console.log(`spear start price after ${ethers.utils.formatEther(spearStartPriceAfter)}`)
    })

    // it("Add Liqui", async () => {
    //     const {cDeltaSpear, cDeltaShield, deltaSpear, deltaShield, lpDelta} = await this.battle.tryAddLiquidity(parseEther("1000"))
    //     const tx = await this.battle.addLiquidity(parseEther("1000"))
    //     await tx.wait()
    // })

    // it("Remove Liqui", async () => {
    //     const {cDeltaSpear, cDeltaShield, deltaSpear, deltaShield, lpDelta} = await this.battle.tryRemoveLiquidity(parseEther("500"))
    //     const tx = await this.battle.removeLiquidity(parseEther("500"))
    //     await tx.wait()
    // })

    // it("Remove Liqui Future", async () => {
    //     let txApprove = await this.battle.approve(this.battle.address, ethers.constants.MaxUint256)
    //     await txApprove.wait()
    //     let allow = await this.battle.allowance(this.deployer.address, this.battle.address)
    //     await allowance(this.battle.address, this.deployer.address, this.battle.address)
    //     await balance(this.battle.address, this.deployer.address)
    //     let tx =await this.battle.removeLiquidityFuture(parseEther("200"))
    //     await tx.wait()
    //     await expect(this.battle.withdrawLiquidityHistory()).to.be.revertedWith("his liqui 0")
    // })

    // it("Set Next Round Spear Price", async () => {
    //     let tx = await this.battle.setNextRoundSpearPrice(parseEther("0.44"))
    //     await tx.wait()
    // })

    it("Settle", async () => {
        let now = new Date().getTime()
        let ts = Math.floor(now/1000) + 24*3600
        await ethers.provider.send("evm_setNextBlockTimestamp", [ts])
        await ethers.provider.send("evm_mine")

        let b = await ethers.provider.getBlock("latest")
        console.log(b)
        const [start, end] = await this.oracle.getRoundTS(0)
        console.log(`start: ${new Date(start.toNumber()*1000).toJSON()}, end: ${new Date(end.toNumber()*1000).toJSON()}`)
        let txPrice = await this.oracle.setPrice("BTC", start, parseEther("100000"))
        await txPrice.wait()
        let txSettle = await this.battle.settle()
        await txSettle.wait()

        // const criBefore = await this.battle.cri()
        // console.log(`cri before: ${criBefore}`);
        // const spearWillGet = await this.battle.tryBuySpear(parseEther("20"))
        // // expect(spearWillGet).to.equal(parseEther())
        // console.log(`spear will get ${formatEther(spearWillGet)}`)
        // // expect(spearWillGet).to.closeTo(parseEther("23.81"), parseEther("0.01"))
        // let txBuySpear = await this.battle.buySpear(parseEther("20"), spearWillGet, Math.floor(new Date().getTime()/1000)+24*3600*2)
        // await txBuySpear.wait()
        // const criAfter = await this.battle.cri()
        // console.log(`cri after: ${criAfter}`)

        // const shieldWillGet = await this.battle.tryBuyShield(parseEther("100"))
        // console.log(`shieldWillGet ${formatEther(shieldWillGet)}`)
        // let txBuyShield = await this.battle.buyShield(parseEther("100"), shieldWillGet, Math.floor(new Date().getTime()/1000)+24*3600*2)
        // await txBuyShield.wait()
        // await getPriceStatus(this.battle, this.cri)
    })

    // it("withdrawLiquidityHistory", async () => {
    //     const amount = await this.battle.tryWithdrawLiquidityHistory()
    //     // expect(formatEther(amount)).to.equals("200")
    //     await expect(() => this.battle.withdrawLiquidityHistory()).to.changeTokenBalance(this.dai, this.deployer, amount)

    // })

    it("Claim", async () => {
        let battleOfUser = await this.battle.connect(this.user1)
        const {ur, rr, amount } = await battleOfUser.tryClaim(this.user1.address)
        console.log(formatEther(amount))
        await battleOfUser.claim()
        // await expect(() => this.battle.claim()).to.changeTokenBalance(this.dai, this.deployer, amount)
    })
})