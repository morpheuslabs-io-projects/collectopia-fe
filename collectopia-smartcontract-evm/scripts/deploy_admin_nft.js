const fetch = require('node-fetch');
const { utils } = require("ethers");
const config = require('./config.js');

async function main() {
    const [Owner] = await ethers.getSigners();
  
    console.log("Owner account:", Owner.address);
    console.log("Account balance:", (await Owner.getBalance()).toString());

    let gas_now = utils.parseUnits('75.0', 'gwei');

    //  Deploy  special collection contract
    console.log('\nDeploy ArtNFT Contract .........');
    const AdminNft = await ethers.getContractFactory('AdminNft', Owner);
    console.log(config.owner,
        config.artNftName,
        config.artNftSymbol,
        config.royaltyReceiver,
        config.royaltyPercentage)
    const adminNft = await AdminNft.deploy(
        config.owner,
        config.artNftName,
        config.artNftSymbol,
        config.royaltyReceiver,
        config.royaltyPercentage,
        { gasPrice: gas_now } 
    );
    await adminNft.deployed();

    console.log('Admin NFT Contract: ', adminNft.address);

    console.log('\n ===== DONE =====')
}
  
main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
});