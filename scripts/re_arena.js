const { utils } = require("ethers");
const { ethers, upgrades } = require("hardhat");

const { arenaAddr, DAI, multicall } = require("../contracts.json")

let arena;

async function restore_arena() {
    const battlenLength = await arena.battleLength()
    console.log(`Now have ${battlenLength} battle`)
    for (let i = 0; i < battlenLength; i++) {
        const battle_addr = await arena.getBattle(i)
        await arena.removeBattle(battle_addr)
    }
    const battlenLength2 = await arena.battleLength()
    console.log(`Now have ${battlenLength2} battle`)
}

async function addSupportUnderlying() {
    await arena.setUnderlying("BTC", true)
    await arena.setUnderlying("stETH", true)
    await arena.setUnderlying("cUSDT", true)
    console.log("add support underlying")
}

async function updateArena() {
    const Arena = await ethers.getContractFactory("Arena")
    await upgrades.upgradeProxy(arenaAddr, Arena)
}

async function createBattle() {
    const dai = await ethers.getContractAt("MockToken", DAI)
    await dai.approve(arenaAddr, utils.parseEther("300000"))
    await arena.createBattle(dai.address, "BTC", ethers.utils.parseEther("200000"),
        ethers.utils.parseEther("0.4"), ethers.utils.parseEther("0.6"), 1, 1, ethers.utils.parseEther("0.09"))
    console.log(`battle length: ${await arena.battleLength()}`)
}

async function getBattles() {
    const battlenLength = await arena.battleLength()
    console.log(`Now have ${battlenLength} battle`)
    let battles = [];
    for (let i = 0; i < battlenLength; i++) {
        const battle_addr = await arena.getBattle(i)
        console.log(`${battle_addr}`)
        battles.push(battle_addr)
        // const battle = await ethers.getContractAt("Battle", battle_addr)
        // const battleInfo = await battle.getBattleInfo()

        // console.log(battleInfo)
    }
    let ABI = ["function getBattleInfo()"];
    let iface = new ethers.utils.Interface(ABI);
    const multi = await ethers.getContractAt("Multicall", multicall)
    const Battle = await ethers.getContractFactory("Battle")
    let calldata = battles.map((addr) => ([addr,
        iface.encodeFunctionData("getBattleInfo")]))
    console.log(calldata)
    const data = await multi.aggregate(calldata)
    console.log(data)
}

async function main() {
    arena = await ethers.getContractAt("Arena", arenaAddr)
    // await addSupportUnderlying()

    // await updateArena()

    // await createBattle()

    await getBattles()
}



main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
})