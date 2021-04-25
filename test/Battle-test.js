const { parseEther, formatEther, formatUnits } = require("@ethersproject/units");
const {expect} = require("chai");
const { ethers } = require("hardhat");
const {deployments, getUnnamedAccounts} = require("hardhat");

describe("Battle", function () {
    let battle;
    let battle1;
    let dai;
    let dai1;
    let deployer;
    let user1;
    let spear;
    let shield;
    let spear1;
    let shield1;

    before(async () => {
        deployer = (await ethers.getSigners())[0]
    })

    beforeEach(async ()=> {
        await deployments.fixture();
        dai = await deployments.get("MockDAI");
        dai = await ethers.getContractAt("MockDAI", dai.address, deployer)
        battle = await deployments.get("Battle");
        console.log(`battle address:${battle.address}, deployer address:${deployer.address}`)
        battle = await ethers.getContractAt("Battle", battle.address, deployer)
    })

    it("should init success", async ()=>{
        const cri = await deployments.read("Battle", {}, "currentRoundId")
        // const cri = await battle.currentRoundId();
        const numSpear = await battle.spearBalanceOf(cri, battle.address)
        const collateralSpear = await battle.collateralSpear(cri)
        const numShield = await battle.shieldBalanceOf(cri, battle.address)
        const collateralShield = await battle.collateralShield(cri)
        console.log(`numSpear ${numSpear}, collateralSpear ${collateralSpear}`)
        console.log(`numShield ${numShield}, collateralShield ${collateralShield}`)
        const currentRoundId = await battle.currentRoundId()
        const roundInfo = await battle.rounds(currentRoundId)
        console.log(roundInfo)
        const round_ids = await battle.roundIds(0)
        console.log(formatUnits(round_ids, 0));
        const am = await battle.buySpearOut(parseEther("2"))
        console.log(formatEther(am))

    })

    it("buy and sell spear", async () => {
        const out = await battle.buySpearOut(parseEther("10"))
        console.log(`buy spear out for 10: ${formatEther(out)}`)
        await dai.approve(battle.address, parseEther("10"))
        await battle.buySpear(parseEther("10"))
        const cri = await battle.currentRoundId()
        let balanceSpear = await battle.spearBalanceOf(cri, deployer.address)
        console.log(`balance spear:${formatEther(balanceSpear)}`)
        // sell
        const sellOut = await battle.sellSpearOut(parseEther("5"))
        console.log(`sell spear out for 5: ${formatEther(sellOut)}`)
        await battle.sellSpear(parseEther("5"))
        balanceSpear = await battle.spearBalanceOf(cri, deployer.address)
        console.log(`balance spear:${formatEther(balanceSpear)}`)

    })

    it("buy and sell shield", async () => {
        const out = await battle.buyShieldOut(parseEther("10"))
        console.log(`buy shield out for 10: ${formatEther(out)}`)
        await dai.approve(battle.address, parseEther("10"))
        await battle.buyShield(parseEther("10"))
        const cri = await battle.currentRoundId()
        let balanceShield = await battle.shieldBalanceOf(cri, deployer.address)
        console.log(`balance shield:${formatEther(balanceShield)}`)
        // sell
        const sellOut = await battle.sellShieldOut(parseEther("5"))
        console.log(`sell shield out for 5: ${formatEther(sellOut)}`)
        await battle.sellShield(parseEther("5"))
        balanceShield = await battle.shieldBalanceOf(cri, deployer.address)
        console.log(`balance shield:${formatEther(balanceShield)}`)

    })

    it("add liquility", async () => {
        await dai.approve(battle.address, parseEther("100"))
        await battle.addLiquility(parseEther("50"))
        const cri = await battle.currentRoundId()
        let spearBalance = await battle.spearBalanceOf(cri, battle.address)
        console.log(`spear balanceOf: ${spearBalance}`)
    })

    it("remove liquility", async () => {
        const cri = await battle.currentRoundId()
        await battle.removeLiquility(parseEther("10"))
        let spearBalance = await battle.spearBalanceOf(cri, battle.address)
        console.log(`spear balanceOf: ${spearBalance}`)
        balanceShield = await battle.shieldBalanceOf(cri, battle.address)
        console.log(`balance shield:${formatEther(balanceShield)}`)
    })

    


})