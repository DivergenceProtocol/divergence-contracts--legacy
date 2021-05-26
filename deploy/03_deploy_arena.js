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
    //         proxyContract: "OptimizedTransparentProxy"
    //     },
    //     log: true
    // })
    const Arena = await ethers.getContractFactory("Arena")
    const arena = await upgrades.deployProxy(Arena, {kind: "uups"})
    await arena.deployed()
    console.log("Arena Proxy deployed at: ", arena.address)
}

module.exports.tags = ["03"]