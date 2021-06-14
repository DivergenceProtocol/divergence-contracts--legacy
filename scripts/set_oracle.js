const {getOHLC} = require("./utils")

async function main() {
  let data = await getOHLC('BTCUSDT', 16)
  console.log(data)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
