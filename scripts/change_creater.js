
const { ethers } = require("hardhat");
const {arenaAddr} = require("../contracts.json")

async function main() {
    const arena = await ethers.getContractAt("Arena", arenaAddr)
    const Creater = await ethers.getContractFactory("Creater")
    const creater = await Creater.deploy()
    await creater.deployed()
    console.log(`Creater deploy at ${creater.address}`)
    await arena.setCreater(creater.address)
    console.log(`finished change creater`)
}

main().then(() => process.exit(0)).catch(error => {
    console.error(error);
    process.exit(1);
})