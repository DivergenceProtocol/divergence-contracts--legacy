import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import { mnemonic, projectId, mainnetMnenonic} from "./secret.json";
import "hardhat-deploy";
import "@typechain/hardhat";
import "@nomiclabs/hardhat-waffle";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-abi-exporter";
import "hardhat-gas-reporter";

// task("tmt", "transfer mock token")

const config: HardhatUserConfig = {
	// defaultNetwork: "kovan",
	networks: {
		mainnet: {
			url: `https://mainnet.infura.io/v3/${projectId}`,
			accounts: {
				mnemonic: mainnetMnenonic
			},
			timeout: 300000,
			gasPrice: 70*10**9
		},
		kovan: {
			url: `https://kovan.infura.io/v3/${projectId}`,
			accounts: {
				mnemonic: mnemonic
			},
			timeout: 300000,
			gas: 12500000
		},
		local: {
			url: "http://127.0.0.1:8545/"
		},
		hardhat: {
			// forking: {
			// 	// url: `https://eth-kovan.alchemyapi.io/v2/RSD2F-evV5npBYzplUb3P-MP7JzdmQbq`,
			// 	// url: `https://arb-rinkeby.g.alchemy.com/v2/74snLVLlDktyappi47p9pfEqUYMA8Ub-`,
			// 	// url: "https://arb1.arbitrum.io/rpc",
			// 	// url: "https://rinkeby.arbitrum.io/rpc",
			// 	url: "https://rinkeby.arbitrum.io/rpc"
			// },
			accounts: {
				mnemonic: mnemonic
			},
		},
		arbi: {
			url: "https://arb1.arbitrum.io/rpc",
      		chainId: 42161,
		},
		arbi_test: {
			// url: "https://rinkeby.arbitrum.io/rpc",
			url: `https://arb-rinkeby.g.alchemy.com/v2/74snLVLlDktyappi47p9pfEqUYMA8Ub-`,
			chainId: 421611,
			accounts: {
				mnemonic: mnemonic
			},
			gas: 200000000
		}
	},
	solidity: {
		version: "0.8.9",
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
	},
	abiExporter: {
		path: './abi',
	},
	gasReporter: {
		currency: 'USD',
		enabled: true,
		// gasPrice: 30
	}
}

export default config;