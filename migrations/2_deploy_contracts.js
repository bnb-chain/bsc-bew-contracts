const BewSwapImplement = artifacts.require("BewSwap");

const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'));

const fs = require('fs');

module.exports = function(deployer, network, accounts) {
  deployer.then(async () => {
    await deployer.deploy(BewSwapImplement, accounts[0], accounts[1], 1000);
  });
};
