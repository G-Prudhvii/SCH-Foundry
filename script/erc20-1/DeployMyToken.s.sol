// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MyToken} from "../../src/erc20-1/MyToken.sol";

contract DeployMyToken is Script {
    MyToken token;

    function run(address owner) public returns (MyToken) {
        vm.startBroadcast();
        token = new MyToken(owner);
        vm.stopBroadcast();

        return token;
    }
}
