const { createWatcher, aggregate } = require("@makerdao/multicall")
const {multicall} = require("../contracts.json")

// Contract addresses used in this example
const MKR_TOKEN = '0xaaf64bfcc32d0f15873a02163e7e500671a4ffcd';
const MKR_WHALE = '0xdb33dfd3d61308c33c63209845dad3e6bfb2c674';
const MKR_FISH = '0x2dfcedcb401557354d0cf174876ab17bfd6f4efd';

let battles = ['0xD4BccA651CFdE68a0FaeC481C273B3248a1B1433', '0x2660C46830B1e33De71BA6Fa2E089B8A9bE52d52', '0x4c8D483890cF258C1dE13c516a2A7A228c680530']
battleCalls = battles.map((addr) => ({ target: addr, call: ['getBattleInfo()'], returns: [['under', 'col', 'peroid', 'set', 'value', 'ratio']], returnTypes: ['string', 'address', 'uint', 'uint', 'uint', 'uint']}))
console.log(battleCalls)



// Preset can be 'mainnet', 'kovan', 'rinkeby', 'goerli' or 'xdai'
const config = {
    rpcUrl: 'https://kovan.infura.io/v3/58073b4a32df4105906c702f167b91d2',
    multicallAddress: '0x2cc8688c5f75e365aaeeb4ea8d6a480405a48d2a',
};

// const result = await aggregate(battleCalls, config)
// console.log(result)
aggregate(battleCalls, config).then((result) => {
    console.log(result)
}).catch((error) => {
    console.log(error)
})

// Create watcher
// const watcher = createWatcher(
//   [
//     {
//       target: MKR_TOKEN,
//       call: ['balanceOf(address)(uint256)', MKR_WHALE],
//       returns: [['BALANCE_OF_MKR_WHALE', val => val / 10 ** 18]]
//     },
//   ],
//   config
// );

// const watcher = createWatcher(battleCalls, config);

// // Subscribe to state updates
// watcher.subscribe(update => {
// console.log(`Update: ${update.type} = ${update.value}`);
// });

// Subscribe to batched state updates
// watcher.batch().subscribe(updates => {
//   // Handle batched updates here
//   // Updates are returned as { type, value } objects, e.g:
//   // { type: 'BALANCE_OF_MKR_WHALE', value: 70000 }
// });

// Subscribe to new block number updates
// watcher.onNewBlock(blockNumber => {
//   console.log('New block:', blockNumber);
// });

// Start the watcher polling
// watcher.start();
