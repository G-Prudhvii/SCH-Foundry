// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {SCHToken} from "../../src/erc20-1/SCHToken.sol";

contract DeploySCHToken is Script {
    SCHToken token;

    function run() public returns (SCHToken) {
        vm.startBroadcast();
        token = new SCHToken();
        vm.stopBroadcast();

        return token;
    }
}
