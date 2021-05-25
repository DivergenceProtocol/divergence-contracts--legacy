const {
    parseEther
} = require("@ethersproject/units");
const {
    ethers
} = require("ethers");

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
    await deploy("Arena", {
        from: deployer,
        proxy: {
            owner: deployer,
            proxyContract: "OpenZeppelinTransparentProxy"
        },
        log: true
    })
}

module.exports.tags = ["02"]