// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../src/11.1. Flashloan Attacks-2/AdvancedVault.sol";
import "../../src/11.1. Flashloan Attacks-2/AttackAdvancedVault.sol";
import "forge-std/Test.sol";

contract TestFLA2 is Test {
    AdvancedVault vault;
    AttackAdvancedVault attackContract;

    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");

    uint256 constant ETH_IN_VAULT = 1000 ether;

    function setUp() public {
        vm.deal(deployer, ETH_IN_VAULT);

        vm.startPrank(deployer);
        vault = new AdvancedVault{value: ETH_IN_VAULT}();
        vm.stopPrank();

        assertEq(address(vault).balance, ETH_IN_VAULT);
    }

    function testFlashLoanAttack() public {
        vm.startPrank(attacker);
        attackContract = new AttackAdvancedVault(address(vault));
        attackContract.attack();
        vm.stopPrank();

        assertEq(address(vault).balance, 0);
        assertEq(address(attacker).balance, ETH_IN_VAULT);
    }
}
