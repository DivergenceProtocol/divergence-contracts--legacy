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
    name_symbols = [
        ["MockDAI", "DAI"],
        ["MockStETH", "stETH"],
        ["MockCUSDT", "cUSDT"]
    ]
    for (let i = 0; i < name_symbols.length; i++) {
        await deploy(name_symbols[i][1], {
            from: deployer,
            contract: "MockToken",
            args: [name_symbols[i][0], name_symbols[i][1]],
            log: true
        })
    }
}

module.exports.tags = ["00"]