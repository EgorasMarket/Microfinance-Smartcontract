require("dotenv").config();
const HDWalletProvider = require("@truffle/hdwallet-provider");

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*", // Match any network id
    },

    ganache: {
      host: "localhost",
      port: 7545,
      network_id: "*",
    },
    jack_dev: {
      provider: () => {
        return new HDWalletProvider(
          process.env.MNEMONIC,
          "http://127.0.0.1:8545",
          0,
          100
        );
      },
      network_id: "*",
      gasLimit: 7000000,
    },
    rinkeby: {
      provider: () => {
        return new HDWalletProvider(
          process.env.MNEMONIC,
          "https://rinkeby.infura.io/v3/6ef74442fd064e4fa9bebf2ef363bc07",
          0,
          100
        );
      },
      network_id: 4,
      confirmations: 2,
    },
  },

  plugins: ["truffle-plugin-verify"],
  api_keys: {
    etherscan: "BYE46S3P3IPA2NK436P99EI8UHNJPQDPAT",
  },
  mocha: {
    //timeout: 100000
  },

  compilers: {
    solc: {
      version: "0.6.10",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
      },
    },
  },
};
