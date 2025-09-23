// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/11.1. Flashloan Attacks-1/Pool.sol";
import "../../src/11.1. Flashloan Attacks-1/Token.sol";
import "../../src/11.1. Flashloan Attacks-1/Solution/AttackPool.sol";

contract TestFLA1 is Test {
    Pool pool;
    Token token;
    AttackPool attackPool;

    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");

    uint256 constant POOL_TOKENS = 100_000_000 ether;

    function setUp() public {
        // Deploy the token and the pool contracts
        vm.startPrank(deployer);

        token = new Token();
        pool = new Pool(address(token));

        // Transfer tokens to the pool
        token.transfer(address(pool), POOL_TOKENS);
        vm.stopPrank();

        // Pool should have 100 million tokens
        assertEq(token.balanceOf(address(pool)), POOL_TOKENS);
        assertEq(token.balanceOf(attacker), 0);
    }

    function testFlashLoan() public {
        // Test the flash loan functionality
        vm.startPrank(attacker);
        attackPool = new AttackPool(address(pool), address(token));
        attackPool.attack();

        vm.stopPrank();

        // Check if the attacker has drained the pool
        assertEq(token.balanceOf(attacker), POOL_TOKENS);
        assertEq(token.balanceOf(address(pool)), 0);
    }
}
