import { BATTLE_IMPL } from '../scripts/const'
import { deployContract } from '../scripts/utils'
import { Battle } from '../src/types'

describe("BattleImpl", function() {
	it("deploy battle impl", async () => {
		let battle = await deployContract<Battle>('Battle')
		process.env[BATTLE_IMPL] = battle.address
		console.log(`battle impl is ${process.env[BATTLE_IMPL]}`)
	})
})