const Web3 = require('web3');

const contractOwner = "0x042ccc750E1099068622Bb521003F207297a40b0"; // replace this address to get encoded abi data
const feeAccount = "0x042ccc750E1099068622Bb521003F207297a40b0"; // replace this address to get encoded abi data
const feePct = "1000"; // replace this amount to get encoded abi data

const abiEncodeData = web3.eth.abi.encodeFunctionCall({
    inputs: [
        {
            name: "owner",
            type: "address"
        },
        {

            name: "feeAccount",
            type: "address"
        },
        {
            name: "feePct",
            type: "uint256"
        }
    ],
    name: "initialize",
    type: "function"
}, [contractOwner, feeAccount, 1000]);

console.log("encoded abi data: ", abiEncodeData)

