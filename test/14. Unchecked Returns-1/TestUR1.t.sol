// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/14. Unchecked Returns-1/DonationMaster.sol";
import "../../src/14. Unchecked Returns-1/MultiSigSafe.sol";

contract TestUR1 is Test {
    DonationMaster donationMaster;
    MultiSigSafe multiSigSafe;

    address deployer = makeAddr("deployer");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");

    uint256 constant ONE_ETH = 1 ether;
    uint256 constant HUNDRED_ETH = 100 ether;
    uint256 constant THOUSAND_ETH = 1000 ether;

    function setUp() public {
        vm.startPrank(deployer);
        donationMaster = new DonationMaster();
        address[] memory signers = new address[](3);
        signers[0] = user1;
        signers[1] = user2;
        signers[2] = user3;
        multiSigSafe = new MultiSigSafe(signers, 2);
        vm.deal(user1, THOUSAND_ETH);
        vm.deal(user2, THOUSAND_ETH);
        vm.deal(user3, THOUSAND_ETH);
        vm.stopPrank();
    }

    function testDonationFlow() public {
        // New donation works correctly
        donationMaster.newDonation(address(multiSigSafe), HUNDRED_ETH);

        uint256 donationId = donationMaster.donationsNo() - 1;

        // Donating to multisig wallet works correctly
        donationMaster.donate{value: ONE_ETH}(donationId);

        // Validate donation details
        (uint256 id, address to, uint256 goal, uint256 donated) = donationMaster.donations(donationId);
        assertEq(id, donationId);
        assertEq(to, address(multiSigSafe));
        assertEq(goal, HUNDRED_ETH);
        assertEq(donated, ONE_ETH);

        // Too big donation fails
        vm.expectRevert("Goal reached, donation is closed");
        donationMaster.donate{value: THOUSAND_ETH}(donationId);
    }

    function testFixedTests() public view {
        assertEq(address(multiSigSafe).balance, ONE_ETH);
    }
}
