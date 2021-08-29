import { ethers } from "hardhat";
import { deploy } from "./utils";

async function deployMockToken() {
	await deploy("MockToken", "DAI", "DAI", 18)
}

async function main() {
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
