// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/12. DoS-2/Auction.sol";
import "../../src/12. DoS-2/AttackAuction.sol";

contract TestDoS2 is Test {
    Auction public auction;
    AttackAuction public attack;

    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    // Set up the auction and attack contracts

    function setUp() public {
        vm.deal(deployer, 10 ether);
        vm.deal(attacker, 10 ether);
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);

        vm.startPrank(deployer);
        auction = new Auction();
        vm.stopPrank();

        vm.startPrank(user1);
        Auction(address(auction)).bid{value: 1 ether}();
        vm.stopPrank();

        assertEq(auction.currentLeader(), user1);
        assertEq(auction.highestBid(), 1 ether);

        vm.startPrank(user2);
        Auction(address(auction)).bid{value: 2 ether}();
        vm.stopPrank();

        assertEq(auction.currentLeader(), user2);
        assertEq(auction.highestBid(), 2 ether);
    }

    function testDoS2Attack() public {
        vm.startPrank(attacker);
        // Deploy the attack contract with the auction address
        attack = new AttackAuction(address(auction));

        // Initial bid from the attacker
        vm.deal(address(attack), 10 ether);

        attack.attack();
        vm.stopPrank();

        assertEq(auction.currentLeader(), address(attack));
        assertEq(auction.highestBid(), 3 ether);

        // Assert that the attack was successful
        uint256 highestBid = auction.highestBid();

        vm.startPrank(user1);
        // Attempt to bid again, which should fail due to the DoS attack
        vm.expectRevert();
        auction.bid{value: highestBid * 3}();
        vm.stopPrank();

        assertTrue(auction.currentLeader() == address(attack), "User1 failed to take over leadership");
    }
}
