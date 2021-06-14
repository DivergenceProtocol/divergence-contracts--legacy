const {deployProxy, getMonthTS, getOHLC} = require("../scripts/utils")

describe("oracle", function() {

    before(async () => {
        let oracle = await deployProxy("Oracle")
        this.oracle = oracle
    })

    it('set month ts', async () => {
        console.log(this.oracle.address)
        let tx = await this.oracle.setMonthTS(await getMonthTS())
        await tx.wait()
        const [criStart, criEnd] = await this.oracle.getRoundTS(2)
        console.log(`${criStart} ${criEnd}`)
        const [nriStart, nriEnd] = await this.oracle.getNextRoundTS(2)
        console.log(`${nriStart} ${nriEnd}`)
    })

    it('set price', async () => {
        let priceData = await getOHLC("BTCUSDT", 16)
        let tx = await this.oracle.setMultiPrice(...priceData)
        console.log(`pending tx: ${tx.hash}`)
    })
})