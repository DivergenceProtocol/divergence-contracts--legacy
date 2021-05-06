const { parseEther } = require("@ethersproject/units");
const { ethers, upgrades } = require("hardhat");

module.exports = async ({
    network,
    getNamedAccounts,
    deployments
}) => {
    const {
        deploy,
        execute,
        get
    } = deployments;
    const {
        deployer
    } = await getNamedAccounts();
    console.log(`${deployer} in ${network.name}`)
    switch (network.name) {
        case "hardhat":
            // break;
        case "ropsten":
            await deploy("Oracle", {
                from: deployer,
                proxy: {
                    owner: deployer,
                    methodName: "initialize",
                    proxyContract : "OpenZeppelinTransparentProxy"
                },
                args: [],
                log: true
            })
            let ts = Math.round(new Date() / 1000)
            await execute("Oracle", {from: deployer, log: true}, "setPrice", "BTC", ts, parseEther("57148"))
            await execute("Oracle", {from: deployer, log: true}, "setPrice", "stETH", ts, parseEther("0.97071873"))
            await execute("Oracle", {from: deployer, log: true}, "setPrice", "cUSDT", ts, parseEther("0.02112284"))

            // const Oracle = await ethers.getContractFactory("Oracle")
            // const oracle = await upgrades.deployProxy(Oracle, ["BTC"])
            // await oracle.deployed();
            // console.log("oracle", oracle.address)
            break
        case "mainnet":
            break
        default:
            console.log("non-network")
    }
}

module.exports.tags = ["01"]