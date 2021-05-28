const { ethers } = require("hardhat")


describe("Battle2", function () {

    let arena;
    let multicall;

    before(async () => {
        let arena_addr = "0x2e50131CD6E3A7736C68f1C530eF3bdFb068F619"
        arena = await ethers.getContractAt("Arena", arena_addr)
        let multicall_abi = [
            "function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData)"
        ]
        multicall = 
    })

    // it("should create battle success", async ()=>{
    //     const Battle = await ethers.getContractFactory("Battle")
    //     const battle = await Battle.deploy()
    //     let collateral = "0x2e50131CD6E3A7736C68f1C530eF3bdFb068F619"
    //     let trackName = "wbtc"
    //     let priceName = "btc"

    //     await battle.init0()
    //     await battle.init()
    // })

    it("Should get battle info", async () => {
        let battle_addr = await arena.getBattle(0)
        battle = await ethers.getContractAt("Battle", battle_addr)
        const battle_info = await battle.getBattleInfo()
        console.log(battle_info)
    })
})