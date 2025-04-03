const dotenv = require("dotenv");
dotenv.config({ path: __dirname + "/.env" });

require('@openzeppelin/hardhat-upgrades');
require("@nomicfoundation/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("@atixlabs/hardhat-time-n-mine");
require("hardhat-deploy");
require("hardhat-gas-reporter");


const mnemonic = process.env.MNEMONIC

module.exports = {
    solidity: {
        compilers: [
            {
                version: "0.8.9"
            }
        ]
    },

    gasReporter: {
        enabled: true
    },

    networks: {
        development: {
            url: "http://127.0.0.1:8545",     // Localhost (default: none)
            accounts: {
                mnemonic: mnemonic,
                count: 10
            },
            live: false, 
            saveDeployments: true
        },
        mainnet: {
            url: process.env.MATIC_POLYGON_PROVIDER,
            accounts: [
                process.env.MAINNET_DEPLOYER,
            ],
            timeout: 900000,
            chainId: 137,
        },
        amoy: {
            url: process.env.AMOY_POLYGON_PROVIDER,
            accounts: [
                process.env.TESTNET_DEPLOYER
            ],
            timeout: 20000,
            chainId: 80002,
        },
        sepolia: {
            url: process.env.SEPOLIA_PROVIDER,
            accounts: [
                process.env.TESTNET_DEPLOYER
            ],
            timeout: 20000,
            chainId: 11155111,
        },
        bsc_testnet: {
            url: `https://data-seed-prebsc-2-s1.binance.org:8545`, // BSC testnet RPC URL
            chainId: 97, // Hardhat's default chain id for local network
            gas: 120000000, // Maximum gas per block
            gasPrice: 10000000000, // Gas price in wei (8 gwei)
            loggingEnabled: true, // Enable gas logging for debugging
            initialBaseFeePerGas: 0, // Set base fee to zero for predictable gas calculations
            accounts:  process.env.TESTNET_DEPLOYER !== undefined ? [process.env.TESTNET_DEPLOYER] : [],
          }
    },

    paths: {
        sources: "./contracts",
        tests: "./tests",
        cache: "./build/cache",
        artifacts: "./build/artifacts",
        deployments: "./deployments"
    },

    etherscan: {
        apiKey: process.env.ETHERSCAN_API_KEY,
        customChains: [
            {
              network: "amoy",
              chainId: 80002,
              urls: {
                apiURL: "https://api-amoy.polygonscan.com/api",
                browserURL: "https://amoy.polygonscan.com"
              }
            }
        ]
    }
}