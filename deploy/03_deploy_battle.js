const { parseEther } = require("@ethersproject/units");
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
    let dai_addr = (await get("DAI")).address;
    let stETH_addr = (await get("stETH")).address;
    let cUSDT_addr = (await get("cUSDT")).address;
    let oracle_addr = (await get("Oracle")).address;
    let arena_addr = (await get("Arena")).address;
    console.log(`arena addr ${arena_addr}`)
    const wd_resu =  await deploy("battle_wbtc_dai", {from: deployer, log: true, contract: "Battle"})
    const st_resu = await deploy("battle_stETH_eth", {from: deployer, log: true, contract: "Battle"})
    const cu_resu = await deploy("battle_cUSDT_usdt", {from: deployer, log: true, contract: "Battle"})

    await execute("DAI", {from: deployer, log: true}, "approve", wd_resu.address,parseEther("30000000000000"))
    await execute("battle_wbtc_dai", {
            from: deployer,
            log: true
        }, "init", dai_addr, oracle_addr, "WBTC-DAI", "BTC", ethers.utils.parseEther("20000"),
        ethers.utils.parseEther("0.6"), ethers.utils.parseEther("0.4"), ethers.utils.parseUnits("5", 16), 0,
        Math.round(new Date() / 1000) + 5 * 60, Math.round(new Date() / 1000) + 10 * 60)
    await execute("Arena", {from: deployer, log: true}, "addBattle", wd_resu.address)
    await execute("stETH", {from: deployer, log: true}, "approve", st_resu.address, parseEther("30000000000000"))
    await execute("battle_stETH_eth", {
            from: deployer,
            log: true
        }, "init", stETH_addr, oracle_addr, "stETH:ETH", "stETH", ethers.utils.parseEther("20000"),
        ethers.utils.parseEther("0.6"), ethers.utils.parseEther("0.4"), ethers.utils.parseUnits("5", 16), 0,
        Math.round(new Date() / 1000) + 5 * 60, Math.round(new Date() / 1000) + 10 * 60)
    await execute("Arena", {from: deployer, log: true}, "addBattle", st_resu.address)
    await execute("cUSDT", {from: deployer, log: true}, "approve", cu_resu.address, parseEther("30000000000000"))
    await execute("battle_cUSDT_usdt", {
            from: deployer,
            log: true
        }, "init", cUSDT_addr, oracle_addr, "cUSDT:USDT", "cUSDT", ethers.utils.parseEther("20000"),
        ethers.utils.parseEther("0.6"), ethers.utils.parseEther("0.4"), ethers.utils.parseUnits("5", 16), 0,
        Math.round(new Date() / 1000) + 5 * 60, Math.round(new Date() / 1000) + 10 * 60)
    await execute("Arena", {from: deployer, log: true}, "addBattle", cu_resu.address)
    
}

module.exports.tags = ["03"]