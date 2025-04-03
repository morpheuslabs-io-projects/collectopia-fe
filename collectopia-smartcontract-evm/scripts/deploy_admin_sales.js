const fetch = require('node-fetch');
const { utils } = require("ethers");
const config = require('./config.js');

async function main() {
    const [Owner] = await ethers.getSigners();
  
    console.log("Owner account:", Owner.address);
    console.log("Account balance:", (await Owner.getBalance()).toString());

    let gas_now = utils.parseUnits('75.0', 'gwei');

    //  Deploy  special collection contract
    console.log('\nDeploy sale Contract .........');
    const NFTSale = await ethers.getContractFactory('AdminSale', Owner);
    console.log(config.collection,
        config.owner, )
    const nftSale = await NFTSale.deploy(
        config.collection,
        config.owner, 
        { gasPrice: gas_now } 
    );
    await nftSale.deployed();

    console.log('nftSale Contract: ', nftSale.address);

    console.log('\n ===== DONE =====')
}
  
main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
});