const HDWalletProvider = require('@truffle/hdwallet-provider');
const fs = require('fs');

// Pastikan file .secret berisi mnemonic wallet kamu (12 kata)
const mnemonic = fs.readFileSync(".secret").toString().trim();

module.exports = {
  networks: {
    // Ganache lokal (default untuk testing)
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
    },

    // Sepolia testnet via Infura
    sepolia: {
      provider: () =>
        new HDWalletProvider(
          mnemonic,
          `https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID`
        ),
      network_id: 11155111, // ID Sepolia
      gas: 5500000,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
    },
  },

  mocha: {
    // timeout: 100000
  },

  compilers: {
    solc: {
      version: "0.8.11",
    },
  },

  db: {
    enabled: false,
  },
};
