const { parseEther, formatUnits } = require("@ethersproject/units");
const { utils } = require("ethers");
const { ethers, network } = require("hardhat");


module.exports = async ({
    getUnnamedAccounts,
    deployments
}) => {
    const {
        deploy,
        run,
        execute,
        get,
        read
    } = deployments;
    const {
        deployer
    } = await getNamedAccounts();
    console.log(`deployer ${deployer}`)
    let dai_addr = (await get("DAI")).address;
    let stETH_addr = (await get("stETH")).address;
    let cUSDT_addr = (await get("cUSDT")).address;
    const arena = await ethers.getContractAt("Arena", "0x2e50131CD6E3A7736C68f1C530eF3bdFb068F619")
    console.log(`arena addr ${arena.address}`)
    await execute("DAI", {from: deployer, log: true}, "approve", arena.address,parseEther("30000000000000"))
    // await execute("Arena", {from: deployer, log: true}, "createBattle", dai_addr, oracle_addr, "WBTC-DAI", "BTC", ethers.utils.parseEther("2000000"),
    //     ethers.utils.parseEther("0.6"), ethers.utils.parseEther("0.4"), ethers.utils.parseUnits("5", 16), 0, 0)
    await arena.createBattle(dai_addr, "BTC", ethers.utils.parseEther("2000000"),
        ethers.utils.parseEther("0.4"), ethers.utils.parseEther("0.6"), 1, 1, ethers.utils.parseEther("0.05"))
    console.log(`battle length: ${await arena.battleLength()}`)

    // await execute("stETH", {from: deployer, log: true}, "approve", arena_addr,parseEther("30000000000000"))
    // await execute("Arena", {from: deployer, log: true}, "createBattle", stETH_addr, oracle_addr, "stETH:ETH", "stETH", ethers.utils.parseEther("2000000"),
    //     ethers.utils.parseEther("0.6"), ethers.utils.parseEther("0.4"), ethers.utils.parseUnits("3", 16), 0, 1)
    
    // await execute("cUSDT", {from: deployer, log: true}, "approve", arena_addr,parseEther("30000000000000"))
    // await execute("Arena", {from: deployer, log: true}, "createBattle", cUSDT_addr, oracle_addr, "cUSDT:USDT", "cUSDT", ethers.utils.parseEther("2000000"),
    //     ethers.utils.parseEther("0.6"), ethers.utils.parseEther("0.4"), ethers.utils.parseUnits("1", 16), 1, 0)

    // let blen = await read("Arena", {from: deployer, log: true}, "battleLength")
    // blen = formatUnits(blen, "wei")
    // console.log(blen)
    // for(i=0; i<3; i++) {
    //     if (i===1) {
    //         continue
    //     }
    //     // console.log(i)
    //     let battle = await read("Arena", {form: deployer, log: true}, "getBattle", i)
    //     // console.log("battle", battle)
    //     // await execute("Arena", {from: deployer, log: true}, "removeBattle", battle)
    //     const [ddd,] = await ethers.getSigners()
    //     let ba = await ethers.getContractFactory("Battle", ddd)
    //     const abi = ["function settle() external"]
    //     const b = new ethers.Contract(battle, abi, ddd)
    //     await b.settle()
    // }
    
}

// function old() {
//     const wd_resu =  await deploy("battle_wbtc_dai", {from: deployer, log: true, contract: "Battle"})
//     const st_resu = await deploy("battle_stETH_eth", {from: deployer, log: true, contract: "Battle"})
//     const cu_resu = await deploy("battle_cUSDT_usdt", {from: deployer, log: true, contract: "Battle"})

//     await execute("DAI", {from: deployer, log: true}, "approve", wd_resu.address,parseEther("30000000000000"))
//     await execute("battle_wbtc_dai", {
//             from: deployer,
//             log: true
//         }, "init", dai_addr, oracle_addr, "WBTC-DAI", "BTC", ethers.utils.parseEther("20000"),
//         ethers.utils.parseEther("0.6"), ethers.utils.parseEther("0.4"), ethers.utils.parseUnits("5", 16), 0,
//         Math.round(new Date() / 1000) + 5 * 60, Math.round(new Date() / 1000) + 10 * 60)
//     await execute("Arena", {from: deployer, log: true}, "addBattle", wd_resu.address)
//     await execute("stETH", {from: deployer, log: true}, "approve", st_resu.address, parseEther("30000000000000"))
//     await execute("battle_stETH_eth", {
//             from: deployer,
//             log: true
//         }, "init", stETH_addr, oracle_addr, "stETH:ETH", "stETH", ethers.utils.parseEther("20000"),
//         ethers.utils.parseEther("0.6"), ethers.utils.parseEther("0.4"), ethers.utils.parseUnits("5", 16), 0,
//         Math.round(new Date() / 1000) + 5 * 60, Math.round(new Date() / 1000) + 10 * 60)
//     await execute("Arena", {from: deployer, log: true}, "addBattle", st_resu.address)
//     await execute("cUSDT", {from: deployer, log: true}, "approve", cu_resu.address, parseEther("30000000000000"))
//     await execute("battle_cUSDT_usdt", {
//             from: deployer,
//             log: true
//         }, "init", cUSDT_addr, oracle_addr, "cUSDT:USDT", "cUSDT", ethers.utils.parseEther("20000"),
//         ethers.utils.parseEther("0.6"), ethers.utils.parseEther("0.4"), ethers.utils.parseUnits("5", 16), 0,
//         Math.round(new Date() / 1000) + 5 * 60, Math.round(new Date() / 1000) + 10 * 60)
//     await execute("Arena", {from: deployer, log: true}, "addBattle", cu_resu.address)
// }

module.exports.tags = ["04"]