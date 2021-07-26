pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract BewSwapUpgradeableProxy is TransparentUpgradeableProxy {
    constructor(address logic, address admin, bytes memory data) TransparentUpgradeableProxy(logic, admin, data) public {
    }
}