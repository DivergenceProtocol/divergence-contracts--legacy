const { utils } = require("ethers");
const { ethers, upgrades } = require("hardhat");

const {arenaAddr, DAI} = require("../contracts.json")

let arena;

async function restore_arena() {
    const battlenLength = await arena.battleLength()
    console.log(`Now have ${battlenLength} battle`)
    for (let i=0; i < battlenLength; i++) {
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
        ethers.utils.parseEther("0.4"), ethers.utils.parseEther("0.6"), 1, 1, ethers.utils.parseEther("0.08"))
    console.log(`battle length: ${await arena.battleLength()}`)
}

async function main() {
    arena = await ethers.getContractAt("Arena", arenaAddr)
    // await addSupportUnderlying()

    // await updateArena()

    await createBattle()
}



main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
})