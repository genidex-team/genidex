const geniDexHelper = require('../helpers/genidex.h')

async function main() {
  const geniDexContract = await geniDexHelper.deploy();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
