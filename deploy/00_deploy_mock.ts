import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const deployFunc: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const {deployments, getNamedAccounts, network} = hre;
    const {deploy, execute, get} = deployments;
    const {deployer} = await getNamedAccounts();
    console.log(`${deployer} in ${network.name}`)
    const name_symbols = [
        // ["MockDAI", "DAI", 18],
        ["MockWETH", "WETH", "18"],
        ["MockUSDC", "USDC", "6"],
        ["MockWBTC", "WBTC", "8"]
    ]

    for (let i = 0; i < name_symbols.length; i++) {
        await deploy(name_symbols[i][1], {
            from: deployer,
            contract: "MockToken",
            args: [name_symbols[i][0], name_symbols[i][1], parseInt(name_symbols[i][2])],
            log: true
        })
    }

}

export default deployFunc
deployFunc.tags = ["00"]