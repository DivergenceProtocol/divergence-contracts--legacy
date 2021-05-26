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
    await deploy("Creater", {
        from: deployer,
        log: true
    })
}

module.exports.tags = ["02"]