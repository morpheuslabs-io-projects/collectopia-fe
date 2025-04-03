const {ethers, utils} = require("ethers");

let mnemonic = "code exchange trash inner check type transfer maze tornado ghost since tumble example minute word";
let mnemonicWallet = ethers.Wallet.fromMnemonic(mnemonic);

console.log(mnemonicWallet.address);

const node = utils.HDNode.fromMnemonic(mnemonic)

// Generate multiple wallets from the HDNode instance
const wallets = []
for (let i = 0; i < 1000; i++) {
  const path = "m/44'/60'/0'/0/" + i
  const wallet = ethers.Wallet.fromMnemonic(mnemonic, path)
  console.log(wallet.address, "=>", wallet.privateKey);
  //wallets.push(wallet)
}

// 0x092345129636BA56E1b0d804ef2b8AEe4d40493b