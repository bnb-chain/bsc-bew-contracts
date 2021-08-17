const BewSwapImpl = artifacts.require("BewSwap");

const fs = require('fs');
const Web3 = require('web3');
const truffleAssert = require('truffle-assertions');
const web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'));

contract('Bew Swap', (accounts) => {
    it('Transfer ownership', async () => {
        const bewSwap = await BewSwapImpl.deployed();

        await bewSwap.transferOwnership(accounts[1], {from: accounts[0]});
        await bewSwap.acceptOwnership({from: accounts[1]});

        let newOwner = await bewSwap.owner();

        assert.ok(newOwner === accounts[1]);
    });

    it('Update Fee', async () => {
        const bewSwap = await BewSwapImpl.deployed();

        await bewSwap.updateFeePct(2000, {from: accounts[1]});
        let newFee = await bewSwap.feePct();
        assert.ok(newFee.toString() === "2000");
    });

    it('Swap eth for exact tokens', async () => {
        const bewSwap = await BewSwapImpl.deployed();

        let swapTx = await bewSwap.swapETHForExactTokens("0xc80251cD06db2383746Ebd85fff5B3c94E5FEfd7", "100000000000000000", ["0xbf49bf2b192330e40339ccbb143592629074c22f", "0xa2C3290cC286688e83Cd37e04553b51Bc8b35d89"], "0x042ccc750E1099068622Bb521003F207297a40b0", 2628767400, {from: "0x042ccc750E1099068622Bb521003F207297a40b0", value:web3.utils.toBN(1e17)});

        truffleAssert.eventEmitted(swapTx, "Swap",(ev) => {
            return ev.amount0Out.toString() === "100000000000000000";
        });

        truffleAssert.eventEmitted(swapTx, "FeeReceived",(ev) => {
            return ev.amount.toString() != "0";
        });

    });

    it('Swap exact eth for tokens', async () => {
        const bewSwap = await BewSwapImpl.deployed();

        let swapTx = await bewSwap.swapExactETHForTokens("0xc80251cD06db2383746Ebd85fff5B3c94E5FEfd7", "1", ["0xbf49bf2b192330e40339ccbb143592629074c22f", "0xa2C3290cC286688e83Cd37e04553b51Bc8b35d89"], "0x042ccc750E1099068622Bb521003F207297a40b0", 2628767400, {from: "0x042ccc750E1099068622Bb521003F207297a40b0", value:web3.utils.toBN(1e10)});

        truffleAssert.eventEmitted(swapTx, "Swap",(ev) => {
            return ev.amount1In.toString() === "10000000000";
        });

        truffleAssert.eventEmitted(swapTx, "FeeReceived",(ev) => {
            return ev.amount.toString() != "0";
        });
    });

    it('Swap tokens for exact tokens', async () => {
        const bewSwap = await BewSwapImpl.deployed();

        const erc20ABIJsonFile = "test/abi/erc20ABI.json";
        const erc20ABI= JSON.parse(fs.readFileSync(erc20ABIJsonFile));
        const swapToken = new web3.eth.Contract(erc20ABI, "0xdf1546436D9EBfF2F5B09bfC4Fa7Ad5822e52177");
        await swapToken.methods.approve(bewSwap.address, "100000000000000000000000000").send({from: "0x042ccc750E1099068622Bb521003F207297a40b0"});

        let swapTx = await bewSwap.swapTokensForExactTokens("0xc80251cD06db2383746Ebd85fff5B3c94E5FEfd7", "1000", "1000", ["0xdf1546436D9EBfF2F5B09bfC4Fa7Ad5822e52177", "0xa2C3290cC286688e83Cd37e04553b51Bc8b35d89"], "0x042ccc750E1099068622Bb521003F207297a40b0", 2628767400, {from: "0x042ccc750E1099068622Bb521003F207297a40b0"});

        truffleAssert.eventEmitted(swapTx, "Swap",(ev) => {
            return ev.amount0Out.toString() === "1000";
        });

        truffleAssert.eventEmitted(swapTx, "FeeReceived",(ev) => {
            return ev.amount.toString() != "0";
        });
    });

    it('Swap exact tokens for tokens', async () => {
        const bewSwap = await BewSwapImpl.deployed();

        const erc20ABIJsonFile = "test/abi/erc20ABI.json";
        const erc20ABI= JSON.parse(fs.readFileSync(erc20ABIJsonFile));
        const swapToken = new web3.eth.Contract(erc20ABI, "0xdf1546436D9EBfF2F5B09bfC4Fa7Ad5822e52177");
        await swapToken.methods.approve(bewSwap.address, "100000000000000000000000000").send({from: "0x042ccc750E1099068622Bb521003F207297a40b0"});

        let swapTx = await bewSwap.swapExactTokensForTokens("0xc80251cD06db2383746Ebd85fff5B3c94E5FEfd7", "1000", "100", ["0xdf1546436D9EBfF2F5B09bfC4Fa7Ad5822e52177", "0xa2C3290cC286688e83Cd37e04553b51Bc8b35d89"], "0x042ccc750E1099068622Bb521003F207297a40b0", 2628767400, {from: "0x042ccc750E1099068622Bb521003F207297a40b0"});

        truffleAssert.eventEmitted(swapTx, "Swap",(ev) => {
            return ev.amount1In.toString() === "1000";
        });

        truffleAssert.eventEmitted(swapTx, "FeeReceived",(ev) => {
            return ev.amount.toString() != "0";
        });
    });

    it('Swap exact tokens for eth', async () => {
        const bewSwap = await BewSwapImpl.deployed();

        const erc20ABIJsonFile = "test/abi/erc20ABI.json";
        const erc20ABI= JSON.parse(fs.readFileSync(erc20ABIJsonFile));
        const swapToken = new web3.eth.Contract(erc20ABI, "0xa2C3290cC286688e83Cd37e04553b51Bc8b35d89");
        await swapToken.methods.approve(bewSwap.address, "100000000000000000000000000").send({from: "0x042ccc750E1099068622Bb521003F207297a40b0"});

        let swapTx = await bewSwap.swapExactTokensForETH("0xc80251cD06db2383746Ebd85fff5B3c94E5FEfd7", "100000", "1", ["0xa2C3290cC286688e83Cd37e04553b51Bc8b35d89", "0xbf49bf2b192330e40339ccbb143592629074c22f"], "0x042ccc750E1099068622Bb521003F207297a40b0", 2628767400, {from: "0x042ccc750E1099068622Bb521003F207297a40b0"});

        truffleAssert.eventEmitted(swapTx, "Swap",(ev) => {
            return ev.amount0In.toString() === "100000";
        });

        truffleAssert.eventEmitted(swapTx, "FeeReceived",(ev) => {
            return ev.amount.toString() != "0";
        });
    });

    it('Swap tokens for exact eth', async () => {
        const bewSwap = await BewSwapImpl.deployed();

        const erc20ABIJsonFile = "test/abi/erc20ABI.json";
        const erc20ABI= JSON.parse(fs.readFileSync(erc20ABIJsonFile));
        const swapToken = new web3.eth.Contract(erc20ABI, "0xa2C3290cC286688e83Cd37e04553b51Bc8b35d89");
        await swapToken.methods.approve(bewSwap.address, "100000000000000000000000000").send({from: "0x042ccc750E1099068622Bb521003F207297a40b0"});

        let swapTx = await bewSwap.swapTokensForExactETH("0xc80251cD06db2383746Ebd85fff5B3c94E5FEfd7", "1000", "1000000", ["0xa2C3290cC286688e83Cd37e04553b51Bc8b35d89", "0xbf49bf2b192330e40339ccbb143592629074c22f"], "0x042ccc750E1099068622Bb521003F207297a40b0", 2628767400, {from: "0x042ccc750E1099068622Bb521003F207297a40b0"});

        truffleAssert.eventEmitted(swapTx, "Swap",(ev) => {
            return ev.amount1Out.toString() === "1000";
        });

        truffleAssert.eventEmitted(swapTx, "FeeReceived",(ev) => {
            return ev.amount.toString() != "0";
        });
    });
});