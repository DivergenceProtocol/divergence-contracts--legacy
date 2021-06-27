const { utils } = require("ethers");
const { ethers, upgrades } = require("hardhat");
const {deployProxy, deploy} = require("./utils")

const { arenaAddr, DAI, multicall, oracleAddr } = require("../contracts.json");
const { parseEther } = require("ethers/lib/utils");

let arena;

async function restore_arena() {
    arena = await ethers.getContractAt("Arena", arenaAddr)
    const battlenLength = await arena.battleLength()
    console.log(`Now have ${battlenLength} battle`)
    for (let i = 0; i < battlenLength; i++) {
        const battle_addr = await arena.getBattle(0)
        await arena.removeBattle(battle_addr)
    }
    const battlenLength2 = await arena.battleLength()
    console.log(`Now have ${battlenLength2} battle`)
}

async function addSupportUnderlying(symbols) {
    for (symbol of symbols) {
        let tx = await arena.setUnderlying(symbol, true)
        console.log(`Pending TX: add support underlying ${tx.hash} `)
        await tx.wait()
    }
}

async function updateArena() {
    const Arena = await ethers.getContractFactory("Arena")
    await upgrades.upgradeProxy(arenaAddr, Arena)
}

async function createBattle() {
    const dai = await ethers.getContractAt("MockToken", DAI)
    let tx = await dai.approve(arena.address, ethers.constants.MaxUint256)
    await tx.wait()
    let txCreateBattle = await arena.createBattle(dai.address, 'BTC', parseEther("10000"), parseEther("0.45"), parseEther("0.55"), 0, 1, parseEther("0.03"))
    console.log(`Pending TX: createBattle ${txCreateBattle.hash}`)
    await txCreateBattle.wait()
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
        const battle = await ethers.getContractAt("Battle", battle_addr)
        const battleInfo = await battle.getBattleInfo()

        console.log(battleInfo)
    }
    // let ABI = ["function getBattleInfo()"];
    // let iface = new ethers.utils.Interface(ABI);
    // const multi = await ethers.getContractAt("Multicall", multicall)
    // const Battle = await ethers.getContractFactory("Battle")
    // let calldata = battles.map((addr) => ([addr,
    //     iface.encodeFunctionData("getBattleInfo")]))
    // console.log(calldata)
    // const data = await multi.aggregate(calldata)
    // console.log(data)
}

async function deployArena() {
    let creater = await deploy("Creater")
    arena = await deployProxy("Arena", creater.address, oracleAddr)
    console.log(`arena ${arena.address}`)
    return arena
}

async function deployAndInit() {
    if (arenaAddr === undefined) {
        await deployArena()
        await addSupportUnderlying(["BTC", "ETH", "stETH", "cUSDT"])
    } else {
        arena = await ethers.getContractAt("Arena", arenaAddr)
    }
}

async function getArenaInfo() {
    const oracleAddr = await  arena.oracle();
    const creater = await arena.creater()
    console.log(`Arena oracle: ${oracleAddr}\n creater: ${creater}`)
}

async function setOracle() {
    await arena.setOracle(oracleAddr)
}

async function main() {
    await restore_arena()
    await deployAndInit()
    await getArenaInfo()
    await createBattle()
    // arena = await ethers.getContractAt("Arena", arenaAddr)
    // await addSupportUnderlying()

    // await updateArena()

    // await createBattle()

    await getBattles()

    // await setOracle()

}



main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
})