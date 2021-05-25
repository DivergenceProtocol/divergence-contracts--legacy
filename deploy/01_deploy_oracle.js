const { parseEther } = require("@ethersproject/units");
const { ethers, upgrades } = require("hardhat");
const csv = require('csv-parser')
const fs = require('fs');

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
        // case "ropsten" || "kovan":
        case "kovan":
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
            // await execute("Oracle", {
            //     from: deployer,
            //     log: []
            // }, "initialize")
            break
        case "mainnet":
            break
        default:
            console.log("non-network")
    }
}

module.exports.tags = ["01"]