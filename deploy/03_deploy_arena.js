const {
    parseEther
} = require("@ethersproject/units");
const {
    ethers, upgrades
} = require("hardhat");

module.exports = async ({
    getUnnamedAccounts,
    deployments
}) => {
    const {
        deploy,
        run,
        execute,
        get
    } = deployments;
    const {
        deployer
    } = await getNamedAccounts();
    console.log(`deployer ${deployer}`)
    // await deploy("Arena", {
    //     from: deployer,
    //     proxy: {
    //         owner: deployer,
    //         proxyContract: "Arena"
    //     },
    //     log: true
    // })
    // const Arena = await ethers.getContractFactory("Arena")
    // const arena = await upgrades.deployProxy(Arena, {kind: "uups"})
    // await arena.deployed()
    // const arena = await ethers.getContractAt("Arena", "0x2e50131cd6e3a7736c68f1c530ef3bdfb068f619")
    // console.log("Arena Proxy deployed at: ", arena.address)
    // await arena.setCreater("0xB85E2020c7D70904CD6cB96848fe0c94841D3645")
    // await arena.setOracle("0xc8fd2d21A4A1C8100Abe2f7B252e921ff1bee425")
}

module.exports.tags = ["03"]