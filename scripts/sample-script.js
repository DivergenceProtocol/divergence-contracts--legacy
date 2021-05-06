// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { formatEther } = require("@ethersproject/units");
const { hre, ethers } = require("hardhat");

async function main() {
  const arena_addr = "0x580258eee85aBF924AbcF62f27a96e6F74c67D65"
  let arena = await ethers.getContractAt("Arena", arena_addr)
  for (i=0; i < 3; i++) {
    battle_addr = await arena.getBattle(i);
    console.log(`${battle_addr}`)
    let battle0 = await ethers.getContractAt("Battle", battle_addr);
    let cri = await battle0.currentRoundId();
    let roundInfo = await battle0.rounds(cri);
    console.log(formatEther(roundInfo.range))
    // await battle0.settle()
  }

  for (i=0; i<3; i++) {
    let addr = await arena.getBattle(0)
    await arena.removeBattle(addr)
  }

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
