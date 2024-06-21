// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {SCHToken} from "../../src/1. erc20-1/SCHToken.sol";

contract TestSCHToken is Test {
    SCHToken token;

    address DEPLOYER = makeAddr("DEPLOYER");
    address USER1 = makeAddr("user1");
    address USER2 = makeAddr("user2");
    address USER3 = makeAddr("user3");

    uint256 public constant DEPLOYER_MINT = 100000;
    uint256 public constant USERS_MINT = 5000;
    uint256 public constant INITIAL_TRANSFER_AMOUNT = 100;
    uint256 public constant INITIAL_ALLOWANCE_AMOUNT = 1000;

    function setUp() external {
        token = new SCHToken();
    }

    function testSCHToken() public {
        token.mint(DEPLOYER, DEPLOYER_MINT);
        token.mint(USER1, USERS_MINT);
        token.mint(USER2, USERS_MINT);
        token.mint(USER3, USERS_MINT);

        uint256 balanceOfUser1 = token.balanceOf(USER1);
        uint256 balanceOfUser2 = token.balanceOf(USER2);
        uint256 balanceOfUser3 = token.balanceOf(USER3);

        assertEq(balanceOfUser1, USERS_MINT);
        assertEq(balanceOfUser2, USERS_MINT);
        assertEq(balanceOfUser3, USERS_MINT);

        vm.prank(USER2);
        token.transfer(USER3, INITIAL_TRANSFER_AMOUNT);

        balanceOfUser2 = token.balanceOf(USER2);
        balanceOfUser3 = token.balanceOf(USER3);

        assertEq(balanceOfUser2, USERS_MINT - INITIAL_TRANSFER_AMOUNT);
        assertEq(balanceOfUser3, USERS_MINT + INITIAL_TRANSFER_AMOUNT);

        vm.prank(USER3);
        token.approve(USER1, INITIAL_ALLOWANCE_AMOUNT);

        uint256 allowanceAmount = token.allowance(USER3, USER1);

        assertEq(allowanceAmount, INITIAL_ALLOWANCE_AMOUNT);

        vm.prank(USER3);
        token.approve(USER1, INITIAL_ALLOWANCE_AMOUNT);

        vm.prank(USER1);
        token.transferFrom(USER3, USER1, INITIAL_ALLOWANCE_AMOUNT);

        balanceOfUser1 = token.balanceOf(USER1);
        balanceOfUser2 = token.balanceOf(USER2);
        balanceOfUser3 = token.balanceOf(USER3);

        assertEq(balanceOfUser1, USERS_MINT + INITIAL_ALLOWANCE_AMOUNT);
        assertEq(balanceOfUser2, USERS_MINT - INITIAL_TRANSFER_AMOUNT);
        assertEq(balanceOfUser3, USERS_MINT + INITIAL_TRANSFER_AMOUNT - INITIAL_ALLOWANCE_AMOUNT);
    }
}
