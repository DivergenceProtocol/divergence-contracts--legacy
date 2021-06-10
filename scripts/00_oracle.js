
const { deployProxy, deploy, attach } = require("./utils");
const {oracleAddr} = require("../contracts.json")

async function deploy_oracle() {
	const oracle = await deployProxy("Oracle")
	console.log(`oracle deploy at ${oracle.address}`)
}

async function initMonthTS() {
	const oracle = await attach("Oracle", oracleAddr)
}

async function main() {

}

main().then(() => process.exit(0)).catch(error => {
	console.error(error);
	process.exit(1);
})