const RewardRegister = artifacts.require("RewardRegister");
const RewardRegisterUpgradeableProxy = artifacts.require("RewardRegisterUpgradeableProxy");

const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'));

const fs = require('fs');

module.exports = function(deployer, network, accounts) {
  deployer.then(async () => {
    await deployer.deploy(RewardRegister);
    const contractOwner = accounts[1];
    const abiEncodeData = web3.eth.abi.encodeFunctionCall({
      "inputs": [
        {
          "internalType": "address",
          "name": "owner",
          "type": "address"
        }
      ],
      "name": "initialize",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }, [contractOwner]);
    await deployer.deploy(RewardRegisterUpgradeableProxy, RewardRegister.address, accounts[0], abiEncodeData);
  });
};
