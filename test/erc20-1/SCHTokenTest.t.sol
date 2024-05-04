// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {SCHToken} from "../../src/erc20-1/SCHToken.sol";
import {DeploySCHToken} from "../../script/erc20-1/DeploySCHToken.s.sol";

contract TestSCHToken is Test {
    SCHToken token;
    DeploySCHToken deployer;

    address USER1 = makeAddr("user1");
    address USER2 = makeAddr("user2");
    address USER3 = makeAddr("user3");

    uint256 public constant INITIAL_SUPPLY = 100000;
    uint256 public constant INITIAL_BALANCE = 5000;
    uint256 public constant INITIAL_ALLOWANCE_AMOUNT = 1000;

    function setUp() external {
        deployer = new DeploySCHToken();
        token = deployer.run();

        vm.startPrank(msg.sender);
        token.mint(USER1, INITIAL_BALANCE);
        token.mint(USER2, INITIAL_BALANCE);
        token.mint(USER3, INITIAL_BALANCE);
        vm.stopPrank();
    }

    function testSCHTotalSupplyOfDeployer() public view {
        uint256 totalSupply = token.totalSupply();
        console.log("totalSupply: ", totalSupply);
        assert(totalSupply == INITIAL_SUPPLY + 15000);
    }

    function testSCHVerifyEachUserHasRightAmountOfTokens() public view {
        // uint256 tokenValue = 5000 * (10 ** token.decimals());
        // uint256 expectedBalance = 5000;

        uint256 balanceOfUser1 = token.balanceOf(USER1);
        uint256 balanceOfUser2 = token.balanceOf(USER2);
        uint256 balanceOfUser3 = token.balanceOf(USER3);

        console.log("Balance Of User1: ", balanceOfUser1);
        console.log("Balance Of User2: ", balanceOfUser2);
        console.log("Balance Of User3: ", balanceOfUser3);

        assertEq(balanceOfUser1, INITIAL_BALANCE);
        assertEq(balanceOfUser2, INITIAL_BALANCE);
        assertEq(balanceOfUser3, INITIAL_BALANCE);
    }

    function testSCHTransferTokens() public {
        uint256 amountOfTokensToTransfer = 100;

        vm.prank(USER2);
        token.transfer(USER3, amountOfTokensToTransfer);

        uint256 balanceOfUser2 = token.balanceOf(USER2);
        uint256 balanceOfUser3 = token.balanceOf(USER3);

        assertEq(balanceOfUser2, INITIAL_BALANCE - 100);
        assertEq(balanceOfUser3, INITIAL_BALANCE + 100);
    }

    function testSCHUserHasAllowance() public {
        vm.prank(USER3);
        token.approve(USER1, INITIAL_ALLOWANCE_AMOUNT);

        uint256 allowanceAmount = token.allowance(USER3, USER1);
        // token.transferFrom(user1, user2, 1000 * (10 ** myToken.decimals()));
        console.log("Allowance Amount: ", allowanceAmount);

        assertEq(allowanceAmount, INITIAL_ALLOWANCE_AMOUNT);
    }

    function testSCHTransferFromFunction() public {
        vm.prank(USER3);
        token.approve(USER1, INITIAL_ALLOWANCE_AMOUNT);

        uint256 allowanceAmount = token.allowance(USER3, USER1);
        console.log("Allowance Amount: ", allowanceAmount);

        vm.prank(USER1);
        token.transferFrom(USER3, USER1, INITIAL_ALLOWANCE_AMOUNT);

        uint256 balanceOfUser1 = token.balanceOf(USER1);
        uint256 balanceOfUser2 = token.balanceOf(USER2);
        uint256 balanceOfUser3 = token.balanceOf(USER3);

        console.log("Balance Of User1: ", balanceOfUser1);
        console.log("Balance Of User2: ", balanceOfUser2);
        console.log("Balance Of User3: ", balanceOfUser3);

        assertEq(balanceOfUser1, INITIAL_BALANCE + INITIAL_ALLOWANCE_AMOUNT);
        assertEq(balanceOfUser2, INITIAL_BALANCE);
        assertEq(balanceOfUser3, INITIAL_BALANCE - INITIAL_ALLOWANCE_AMOUNT);
    }
}
