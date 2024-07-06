// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {EtherBank} from "../../src/6. ReEntrancy Exercise-1/EtherBank.sol";
// import {EtherBank} from "../../src/6. ReEntrancy Exercise-1/solution/EtherBankSecured.sol";
import {Attacker} from "../../src/6. ReEntrancy Exercise-1/Attacker.sol";

contract TestEtherBank is Test {
    EtherBank bank;
    Attacker attackerContract;

    address deployer = makeAddr("deployer");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address user4 = makeAddr("user4");
    address attacker = makeAddr("attacker");

    uint256 constant USER1_DEPOSIT = 12 ether;
    uint256 constant USER2_DEPOSIT = 6 ether;
    uint256 constant USER3_DEPOSIT = 28 ether;
    uint256 constant USER4_DEPOSIT = 63 ether;
    uint256 constant ATTACKER_DEPOSIT = 1 ether;

    uint256 constant TOTAL_DEPOSIT = USER1_DEPOSIT + USER2_DEPOSIT + USER3_DEPOSIT + USER4_DEPOSIT;

    function setUp() public {
        vm.prank(deployer);
        bank = new EtherBank();

        vm.deal(user1, USER1_DEPOSIT);
        vm.deal(user2, USER2_DEPOSIT);
        vm.deal(user3, USER3_DEPOSIT);
        vm.deal(user4, USER4_DEPOSIT);
        vm.deal(attacker, ATTACKER_DEPOSIT);

        vm.prank(user1);
        bank.depositETH{value: USER1_DEPOSIT}();
        vm.prank(user2);
        bank.depositETH{value: USER2_DEPOSIT}();
        vm.prank(user3);
        bank.depositETH{value: USER3_DEPOSIT}();
        vm.prank(user4);
        bank.depositETH{value: USER4_DEPOSIT}();

        assertEq(bank.balances(attacker), 0);
        assertEq(address(bank).balance, TOTAL_DEPOSIT);
    }

    function testAttack() public {
        vm.startPrank(attacker);

        attackerContract = new Attacker{value: ATTACKER_DEPOSIT}(address(bank));
        attackerContract.attack();
        vm.stopPrank();

        console.log("Attackers Final Balance: ", attacker.balance);
        console.log("Bank Final Balance: ", address(bank).balance);

        assertEq(address(bank).balance, 0);
        assertGt(attacker.balance, TOTAL_DEPOSIT);
    }
}
