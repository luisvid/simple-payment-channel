require('dotenv').config();
const Web3 = require('web3');

module.exports = {
  migrations_directory: './migrations',
  compilers: {
    solc: {
      version: "0.5.2",
    },
  },
  networks: {
    development: {
      provider: new Web3.providers.HttpProvider(
        "http://localhost:8545"
      ),
      mnemonic: 'nose phone clip fee agent crop decorate spell album february oppose anxiety',
      network_id: '*' // Match any network id,
    },
    coverage: {
      host: '127.0.0.1',
      port: 8545,
      network_id: '*',
    },
  }
}