const { parseEther, formatEther } = require("ethers/lib/utils")
import { upgrades, ethers} from "hardhat";
import { BigNumberish, Contract} from "ethers";
// const {deployProxy, getMonthTS, getOHLC} = require("../scripts/utils")
import { deployProxy, getMonthTS, getOHLC } from "../scripts/utils";
import { Oracle } from "../src/types";



describe("oracle", function() {
    let oracle: Oracle;
    // let oracle: Contract;
    before(async () => {
        oracle = (await deployProxy("Oracle")) as Oracle
        // const OracleFac = await ethers.getContractFactory("Oracle")
        // oracle = await oracleFac.deploy()
        // oracle = await upgrades.deployProxy(OracleFac, {kind: 'uups'})
        // await ethers.getContractFactory()
        // process.env.ORACLE = oracle.address
        // const OracleFac = await ethers.getContractFactory("Oracle")
        // oracle = (await upgrades.deployProxy(OracleFac, {kind: "uups"})) as Oracle
        // oracle = await upgrades.deployProxy(OracleFac, {kind: "uups"}) as Oracle
        process.env.ORACLE = oracle.address
    })

    it('set month ts', async () => {
        console.log(oracle.address)
        let tsArray = await getMonthTS()
        // console.log(tsArray)
        let tx = await oracle.setMonthTS(tsArray)
        await tx.wait()
        const [criStart, criEnd] = await oracle.getRoundTS(2)
        console.log(`${criStart} ${criEnd}`)
        const [nriStart, nriEnd] = await oracle.getNextRoundTS(2)
        console.log(`${nriStart} ${nriEnd}`)
    })

    it('set price', async () => {
        let priceData = await getOHLC("BTCUSDT", 31*3)
        if (priceData === undefined) {
            console.error("get priceData error")
            process.exit(1)
        } else {
            console.log(priceData)
            let tx = await oracle.setMultiPrice(...priceData)
            console.log(`pending tx: ${tx.hash}`)
        }
    })

    it("strike price", async () => {
        let {strikePrice, strikePriceOver, strikePriceUnder} = await oracle.getStrikePrice("BTC", 0, 3, parseEther("6523"))
        console.log(`${formatEther(strikePrice)} ${formatEther(strikePriceUnder)} ${formatEther(strikePriceOver)}`)
    })

    it("get TS", async () => {
        let {start, end}: {start: BigNumberish, end: BigNumberish} = await oracle.getTS(0, 0)
        console.log(`start ${new Date(start.toNumber()*1000).toJSON()}, end ${new Date(end.toNumber()*1000).toJSON()}`)
        let openPrice = await oracle.historyPrice("BTC", start)
        console.log(`openPrice: ${formatEther(openPrice)}`)

        let [startWeek, endWeek]: [startWeek: BigNumberish, endWeek: BigNumberish] = await oracle.getTS(1, 1)
        console.log(`start ${new Date(startWeek.toNumber()*1000).toJSON()}, end ${new Date(endWeek.toNumber()*1000).toJSON()}`)

        
        let [startMonth, endMonth]: [startMonth: BigNumberish, endMonth: BigNumberish] = await oracle.getTS(2, 0)
        console.log(`start ${new Date(startMonth.toNumber()*1000).toJSON()}, end ${new Date(endMonth.toNumber()*1000).toJSON()}`)
    })

    it("getSpacePrice", async () => {
        let oraclePrice = parseEther("5000")
        let rawPrice = parseEther("3811")
        // let [startPrice, strike] = await oracle.getStrikePrice("BTC", 0, 0, parseEther("0.3"))
        let price = await oracle.getSpacePrice(rawPrice, 0)
        console.log(`price is ${formatEther(price)}`)
    })
})