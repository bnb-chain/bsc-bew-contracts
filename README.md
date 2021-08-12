# BEW Swap

## Generate contracts from templates

```javascript
npm run generate
```

## Test

Generate test contracts from templates:
```javascript
npm run generate-test
```

Run tests:

```javascript
npm run truffle:test
```

Run coverage:

```javascript
npm run coverage
```

## Deploy contracts

### Generate owner and admin addresses

Generate owner, admin and fee addresses.

### Deploy `BewSwapImplement` contract

Use remix to deploy `BewSwap` contract.

### Get encoded abi data for proxy

Replace the owner address in file `./test/TestEncodeProxyConstructor.js`, and run:

```shell script
npm run truffle:encode
```

Then the encoded abi data will be printed in the console.

### Deploy `BewSwapUpgradeableProxy` contract

Use remix to deploy `BewSwapUpgradeableProxy` contract with the encoded abi data.