// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RealtyToken} from "../../src/10. Replay Attack-2/RealtyToken.sol";
import {RealtySale} from "../../src/10. Replay Attack-2/RealtySale.sol";
import {AttackrealtySale} from "../../src/10. Replay Attack-2/AttackRealtySale.sol";
import "forge-std/Test.sol";

contract TestRA2 is Test {
    RealtySale public realtySale;
    RealtyToken public realtyToken;

    address public deployer = makeAddr("deployer");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public attacker = makeAddr("attacker");

    uint256 constant SHARE_PRICE = 1 ether;
    uint256 constant ATTACKER_INITIAL_BALANCE = 1 ether;

    function setUp() public {
        vm.startPrank(deployer);
        realtySale = new RealtySale();
        realtyToken = RealtyToken(realtySale.getTokenContract());
        vm.stopPrank();

        vm.deal(attacker, ATTACKER_INITIAL_BALANCE);
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);

        // Buy without sending ETH should fail
        vm.prank(user1);
        vm.expectRevert("not enough ETH");
        realtySale.buy();

        // Buy with enough ETH should succeed
        vm.prank(user1);
        realtySale.buy{value: SHARE_PRICE}();

        vm.prank(user2);
        realtySale.buy{value: SHARE_PRICE}();

        // 2 ETH should be locked in the contract
        assertEq(address(realtySale).balance, 2 ether);

        // Check token balances
        assertEq(realtyToken.balanceOf(user1), 1);
        assertEq(realtyToken.balanceOf(user2), 1);
    }

    function testAttack() public {
        vm.startPrank(attacker);
        AttackrealtySale attackContract = new AttackrealtySale(address(realtySale));
        for (uint256 i = 0; i < 98; i++) {
            attackContract.attack();
        }
        vm.stopPrank();

        // Attacker should have drained all tokens
        assertEq(realtyToken.balanceOf(address(attacker)), 98);

        // No tokens should be left for sale
        assertEq(realtyToken.lastTokenID(), realtyToken.maxSupply());
    }
}
