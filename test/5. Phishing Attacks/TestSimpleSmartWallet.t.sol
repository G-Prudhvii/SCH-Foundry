// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {SimpleSmartWallet} from "../../src/5. Phishing Attacks/SimpleSmartWallet.sol";
import {MaliciousCharity} from "../../src/5. Phishing Attacks/MaliciousCharity.sol";

contract TestSimpleSmartWallet is Test {
    SimpleSmartWallet wallet;
    MaliciousCharity charity;

    address fundManager = makeAddr("manager");
    address attacker = makeAddr("attacker");

    uint256 constant HEDGE_FUND_AMOUNT = 2800 ether;
    uint256 constant CHARITY_DONATION = 0.1 ether;

    function setUp() public {
        vm.deal(fundManager, HEDGE_FUND_AMOUNT);

        // Deploy smart wallet and deposit ETH
        vm.prank(fundManager);
        wallet = new SimpleSmartWallet{value: HEDGE_FUND_AMOUNT}();

        assertEq(address(wallet).balance, HEDGE_FUND_AMOUNT);

        // Deploy Malicious Charity
        vm.prank(attacker);
        charity = new MaliciousCharity(address(wallet));
    }

    function testAttack() public {
        console.log("wallet Address: ", wallet.walletOwner());
        console.log("fundManager Address: ", address(fundManager));

        // Fund manager is tricked to send a donation to the "charity" (attacker's contract)
        vm.prank(fundManager, fundManager);
        wallet.transfer(payable(address(charity)), CHARITY_DONATION);

        // Smart wallet supposed to be emptied
        assertEq(address(wallet).balance, 0);

        // Attacker supposed to own the stolen ETH
        assertGe(address(attacker).balance, HEDGE_FUND_AMOUNT);
    }
}
