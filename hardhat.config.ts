import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import { mnemonic, projectId } from "./secret.json";
import "hardhat-deploy";
import "@typechain/hardhat";
import "@nomiclabs/hardhat-waffle";
import "@openzeppelin/hardhat-upgrades";

// task("tmt", "transfer mock token")

const config: HardhatUserConfig = {
	// defaultNetwork: "kovan",
	networks: {
		kovan: {
			url: `https://kovan.infura.io/v3/${projectId}`,
			accounts: {
				mnemonic: mnemonic
			}
		},
		local: {
			url: "http://127.0.0.1:8545/"
		},
	},
	solidity: {
		version: "0.8.5",
		settings: {
			optimizer: {
				enabled: true,
				runs: 200
			}
		}
	},
	namedAccounts: {
		deployer: {
			default: 0
		}
	},
	typechain: {
		outDir: 'src/types',
    		target: 'ethers-v5',
    		alwaysGenerateOverloads: false, // should overloads with full signatures like deposit(uint256) be generated always, even if there are no overloads?
    		externalArtifacts: ['externalArtifacts/*.json'], 
	}
}

export default config;