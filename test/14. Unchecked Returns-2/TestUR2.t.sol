// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/14. Unchecked Returns-2/Escrow.sol";
import "../../src/14. Unchecked Returns-2/EscrowNFT.sol";
import "../../src/14. Unchecked Returns-2/AttackEscrow.sol";
import "../../src/14. Unchecked Returns-2/EscrowSecured.sol";

contract TestUR2 is Test {
    Escrow public escrow;
    EscrowNFT public escrowNFT;
    AttackEscrow public attackEscrow;
    EscrowSecured public escrowSecured;

    address deployer = makeAddr("deployer");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address attacker = makeAddr("attacker");

    uint256 constant ONE_MONTH = 30 days;

    uint256 constant USER1_ESCROW_AMOUNT = 10 ether;
    uint256 constant USER2_ESCROW_AMOUNT = 54 ether;
    uint256 constant USER3_ESCROW_AMOUNT = 72 ether;

    function setUp() public {
        vm.deal(user1, USER1_ESCROW_AMOUNT);
        vm.deal(user2, USER2_ESCROW_AMOUNT);
        vm.deal(user3, USER3_ESCROW_AMOUNT);

        // Set attacker balance to 2 ETH
        vm.deal(attacker, 2 ether);

        // Deploy EscrowNFT contract
        vm.startPrank(deployer);
        escrowNFT = new EscrowNFT();

        // Deploy Escrow contract
        escrow = new Escrow(address(escrowNFT));
        escrowNFT.transferOwnership(address(escrow));
        vm.stopPrank();
    }

    function testEscrowNFTTests() public {
        // User1 escrows 10 ETH for 1 month to user2
        vm.startPrank(user1);
        escrow.escrowEth{value: USER1_ESCROW_AMOUNT}(user2, ONE_MONTH);
        vm.stopPrank();

        uint256 tokenId = escrowNFT.tokenCounter();

        // User2 can't redeem before time
        vm.startPrank(user2);
        vm.expectRevert("Escrow period not expired.");
        escrow.redeemEthFromEscrow(tokenId);
        vm.stopPrank();

        // Fast forward time by 1 month + 1 second
        vm.warp(block.timestamp + ONE_MONTH + 1);

        // Another user can't redeem if they don't own the token
        vm.startPrank(user3);
        vm.expectRevert("Must own token to claim underlying ETH");
        escrow.redeemEthFromEscrow(tokenId);
        vm.stopPrank();

        // Recipient can withdraw after time
        vm.startPrank(user2);
        uint256 balanceBefore = user2.balance;
        escrow.redeemEthFromEscrow(tokenId);
        uint256 balanceAfter = user2.balance;
        assertGt(balanceAfter, balanceBefore + USER1_ESCROW_AMOUNT - 0.01 ether); // accounting for gas
        vm.stopPrank();
    }

    function testExploit() public {
        // User1 escrows 10 ETH for 1 month to user2
        vm.prank(user1);
        escrow.escrowEth{value: USER1_ESCROW_AMOUNT}(user2, ONE_MONTH);

        // User2 escrows 54 ETH for 1 month to user1
        vm.prank(user2);
        escrow.escrowEth{value: USER2_ESCROW_AMOUNT}(user1, ONE_MONTH);

        // User3 escrows 72 ETH for 1 month to user1
        vm.prank(user3);
        escrow.escrowEth{value: USER3_ESCROW_AMOUNT}(user1, ONE_MONTH);

        /**
         * CODE YOUR SOLUTION HERE
         */
        // We will deposit 2 ETH to ourselves for 0 duration
        // We will call the redeem function in a loop until all the ETH is drained

        uint256 attackerInitialBalance = attacker.balance;
        vm.startPrank(attacker);
        attackEscrow = new AttackEscrow(address(escrowNFT), address(escrow));
        attackEscrow.attack{value: 2 ether}();

        // Attacker should drain all ETH from the contract
        assertGt(
            attacker.balance,
            attackerInitialBalance + USER1_ESCROW_AMOUNT + USER2_ESCROW_AMOUNT + USER3_ESCROW_AMOUNT - 0.1 ether
        ); // accounting for gas
    }

    function testSecuredContract() public {
        // Deploy EscrowSecured contract
        vm.prank(deployer);
        escrowSecured = new EscrowSecured(address(escrowNFT));
        //escrowNFT.transferOwnership(address(escrowSecured));

        // User1 escrows 10 ETH for 1 month to user2
        vm.prank(user1);
        escrow.escrowEth{value: USER1_ESCROW_AMOUNT}(user2, ONE_MONTH);

        // User2 escrows 54 ETH for 1 month to user1
        vm.prank(user2);
        escrow.escrowEth{value: USER2_ESCROW_AMOUNT}(user1, ONE_MONTH);

        // User3 escrows 72 ETH for 1 month to user1
        vm.prank(user3);
        escrow.escrowEth{value: USER3_ESCROW_AMOUNT}(user1, ONE_MONTH);

        vm.startPrank(attacker);
        attackEscrow = new AttackEscrow(address(escrowNFT), address(escrowSecured));
        vm.expectRevert();
        attackEscrow.attack{value: 2 ether}();
        vm.stopPrank();

        // Attacker should not be able to drain any ETH from the contract
        assertEq(attacker.balance, 2 ether);
    }
}
