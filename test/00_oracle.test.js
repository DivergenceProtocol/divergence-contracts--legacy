const { parseEther, formatEther } = require("ethers/lib/utils")
const {deployProxy, getMonthTS, getOHLC} = require("../scripts/utils")

describe("oracle", function() {

    before(async () => {
        let oracle = await deployProxy("Oracle")
        this.oracle = oracle
        process.env.ORACLE = oracle.address
    })

    it('set month ts', async () => {
        console.log(this.oracle.address)
        let tsArray = await getMonthTS()
        // console.log(tsArray)
        let tx = await this.oracle.setMonthTS(tsArray)
        await tx.wait()
        const [criStart, criEnd] = await this.oracle.getRoundTS(2)
        console.log(`${criStart} ${criEnd}`)
        const [nriStart, nriEnd] = await this.oracle.getNextRoundTS(2)
        console.log(`${nriStart} ${nriEnd}`)
    })

    it('set price', async () => {
        let priceData = await getOHLC("BTCUSDT", 31*3)
        let tx = await this.oracle.setMultiPrice(...priceData)
        console.log(`pending tx: ${tx.hash}`)
    })

    it("strike price", async () => {
        let {strikePriceOver, strikePriceUnder} = await this.oracle.getStrikePrice("BTC", 0, 0, parseEther("0.05"))
        console.log(`${formatEther(strikePriceUnder)} ${formatEther(strikePriceOver)}`)
    })

    it("get TS", async () => {
        let {start, end} = await this.oracle.getTS(0, 0)
        console.log(`start ${new Date(start*1000).toJSON()}, end ${new Date(end*1000).toJSON()}`)
        let openPrice = await this.oracle.historyPrice("BTC", start)
        console.log(`openPrice: ${formatEther(openPrice)}`)

        let [startWeek, endWeek] = await this.oracle.getTS(1, 1)
        console.log(`start ${new Date(startWeek*1000).toJSON()}, end ${new Date(endWeek*1000).toJSON()}`)

        
        let [startMonth, endMonth] = await this.oracle.getTS(2, 0)
        console.log(`start ${new Date(startMonth*1000).toJSON()}, end ${new Date(endMonth*1000).toJSON()}`)
    })
})