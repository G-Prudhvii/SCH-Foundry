// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Game2} from "../../src/3.1 Randomness Vulnerabilities/Game2.sol";
import {Attack2} from "../../src/3.1 Randomness Vulnerabilities/Attack2.sol";

contract TestGame2 is Test {
    Game2 gameContract;
    Attack2 attackContract;

    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");

    uint256 INITIAL_POT = 20 ether;
    uint256 GAME_FEE = 1 ether;

    function setUp() public {
        vm.deal(deployer, 20 ether);

        vm.prank(deployer);
        gameContract = new Game2{value: INITIAL_POT}();

        console.log("Game Balance: ", address(gameContract).balance);

        assertEq(address(gameContract).balance, INITIAL_POT);
    }

    function testAttack() public {
        vm.deal(attacker, 5 ether);
        uint256 attackersInitialBalance = address(attacker).balance;

        vm.startPrank(attacker);
        attackContract = new Attack2(address(gameContract));

        for (uint256 i = 0; i < 5; i++) {
            attackContract.attack{value: GAME_FEE}();
            vm.roll(block.number + 1 + i);
        }
        vm.stopPrank();

        // Game funds were stolen
        console.log("Game Balance: ", address(gameContract).balance);
        assertEq(address(gameContract).balance, 0);

        // Attacker supposed to own the stolen ETH
        console.log("Attacker Balance: ", address(attacker).balance);
        assertEq(attacker.balance, INITIAL_POT + attackersInitialBalance);
    }
}
