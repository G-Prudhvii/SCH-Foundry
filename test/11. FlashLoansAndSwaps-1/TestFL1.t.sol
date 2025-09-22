// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {Pool} from "../../src/11. FlashLoansAndSwaps-1/Pool.sol";
import {Receiver} from "../../src/11. FlashLoansAndSwaps-1/Receiver.sol";
import {GreedyReceiver} from "../../src/11. FlashLoansAndSwaps-1/GreedyReceiver.sol";

contract TestFL1 is Test {
    Pool private pool;
    Receiver private receiver;
    GreedyReceiver private greedyReceiver;

    address deployer = makeAddr("deployer");
    address user = makeAddr("user");

    uint256 constant POOL_BALANCE = 1000 ether;

    function setUp() public {
        // Deploy the Pool contract with initial balance
        vm.deal(deployer, POOL_BALANCE);
        vm.prank(deployer);
        pool = new Pool{value: POOL_BALANCE}();
    }

    function testPool() public {
        // Ensure the pool has the correct initial balance
        assertEq(address(pool).balance, POOL_BALANCE);

        // Ensure that flash loan reverts if requested amount exceeds pool balance
        vm.startPrank(user);
        vm.expectRevert("Not enough ETH in pool");
        pool.flashLoan(POOL_BALANCE + 1);
    }

    function testFlashLoan() public {
        vm.prank(user);
        receiver = new Receiver(address(pool));
        vm.deal(address(receiver), 1 ether);

        // Test the flash loan functionality
        uint256 loanAmount = 100 ether;
        receiver.executeFlashLoan(loanAmount);
    }

    function testGreedyReceiver() public {
        // Test the greedy receiver functionality
        greedyReceiver = new GreedyReceiver(address(pool));
        uint256 loanAmount = 100 ether;
        vm.expectRevert("Flash loan hasn't been paid back");
        greedyReceiver.executeFlashLoan(loanAmount);
    }
}
