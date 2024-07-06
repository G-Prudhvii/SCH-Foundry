// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ApesAirdrop} from "../../src/6. ReEntrancy Exercise-2/ApesAirdrop.sol";
// import {ApesAirdrop} from "../../src/6. ReEntrancy Exercise-2/solution/ApesAirdropSecured.sol";
import {AttackApesAirdrop} from "../../src/6. ReEntrancy Exercise-2/AttackApesAirdrop.sol";

contract TestApesAirdrop is Test {
    ApesAirdrop apes;
    AttackApesAirdrop attackContract;

    address deployer = makeAddr("deployer");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address user4 = makeAddr("user4");
    address attacker = makeAddr("attacker");

    uint256 constant TOTAL_SUPPLY = 50;

    function setUp() public {
        address[] memory users = new address[](5);
        users[0] = user1;
        users[1] = user2;
        users[2] = user3;
        users[3] = user4;
        users[4] = attacker;

        vm.startPrank(deployer);
        apes = new ApesAirdrop();
        apes.addToWhitelist(users);

        for (uint256 i = 0; i < users.length; i++) {
            assertEq(apes.isWhitelisted(users[i]), true);
        }

        vm.stopPrank();
    }

    function testAttack() public {
        vm.startPrank(attacker);
        attackContract = new AttackApesAirdrop(address(apes));
        apes.grantMyWhitelist(address(attackContract));
        vm.stopPrank();
        attackContract.exploit();

        assertEq(apes.balanceOf(attacker), TOTAL_SUPPLY);
        console.log("Attackers Total Ape NFT balance: ", apes.balanceOf(attacker));
    }
}
