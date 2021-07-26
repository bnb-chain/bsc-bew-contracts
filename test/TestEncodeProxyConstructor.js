const Web3 = require('web3');

const contractOwner = "0x042ccc750E1099068622Bb521003F207297a40b0"; // replace this address to get encoded abi data
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
console.log("encoded abi data: ", abiEncodeData)
