// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/16. DAO Attack-1/RainbowAllianceToken.sol";

/**
 * @dev run command: forge test --mc TestDAO1 -vvv
 */
contract TestDAO1 is Test {
    RainbowAllianceToken public rat;

    address deployer = makeAddr("deployer");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");

    uint256 constant DEPLOYER_MINT = 1000 ether;
    uint256 constant USERS_MINT = 100 ether;
    uint256 constant USER2_BURN = 30 ether;

    function setUp() public {
        // Deploy RainbowAllianceToken contract
        vm.startPrank(deployer);
        rat = new RainbowAllianceToken();

        // Mint tokens to deployer and users
        rat.mint(deployer, DEPLOYER_MINT);
        rat.mint(user1, USERS_MINT);
        rat.mint(user2, USERS_MINT);

        // Burn some tokens from user2
        rat.burn(user2, USER2_BURN);
        vm.stopPrank();
    }

    function testGovernance() public {
        // Can't create proposal without voting rights
        vm.startPrank(user3);
        vm.expectRevert("no voting rights");
        rat.createProposal("Proposal by user3");
        vm.stopPrank();

        // Should be able to create proposal with voting rights
        vm.startPrank(deployer);
        rat.createProposal("Proposal by deployer");
        vm.stopPrank();

        // Can't vote without voting rights
        vm.startPrank(user3);
        vm.expectRevert("no voting rights");
        rat.vote(1, true);
        vm.stopPrank();

        // Can't vote twice
        vm.startPrank(deployer);
        vm.expectRevert("already voted");
        rat.vote(1, true);
        vm.stopPrank();

        // Non-existent proposal, should revert
        vm.startPrank(user2);
        vm.expectRevert("proposal doesn't exist");
        rat.vote(2, true);
        vm.stopPrank();

        // Valid votes
        vm.startPrank(user1);
        rat.vote(1, true);
        vm.stopPrank();

        vm.startPrank(user2);
        rat.vote(1, false);
        vm.stopPrank();

        // Check proposal results
        (uint256 id, string memory description, uint256 yes, uint256 no) = rat.getProposal(1);

        // Supposed to be 1100 yes [Deployer - 1000, User1 - 100]
        assertEq(yes, USERS_MINT + DEPLOYER_MINT);

        // Supposed to be 70 no [User2 - 70 (100 - 30 burned)]
        assertEq(no, USERS_MINT - USER2_BURN);
    }

    function testPOC() public {
        // Transfer tokens from user1 to user3
        // User1 should lose voting power
        // User3 should have gained voting power
        // User1 should not be able to create proposal or vote anymore

        uint256 user1Balance = rat.balanceOf(user1);

        vm.startPrank(user1);
        rat.transfer(user3, user1Balance);

        vm.expectRevert("no voting rights");
        rat.createProposal("Proposal by user1");

        vm.stopPrank();
    }
}
