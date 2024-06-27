// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Game} from "../../src/3. Randomness Vulnerabilities-1/Game.sol";
import {Attacker} from "../../src/3. Randomness Vulnerabilities-1/Attack.sol";

contract TestGame is Test {
    Game gameContract;
    Attacker attackContract;

    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");

    uint256 GAME_POT = 10 ether;

    function setUp() public {
        // Deploy wallet and deposit 10 ETH
        vm.deal(deployer, 12 ether);

        vm.prank(deployer);
        gameContract = new Game{value: GAME_POT}();
        console.log("Game Balance: ", address(gameContract).balance);

        assertEq(address(gameContract).balance, GAME_POT);
    }

    function testAttack() public {
        vm.startPrank(attacker);
        attackContract = new Attacker(address(gameContract));
        attackContract.attack();
        vm.stopPrank();

        // Game funds were stolen
        console.log("Game Balance: ", address(gameContract).balance);
        assertEq(address(gameContract).balance, 0);

        // Attacker supposed to own the stolen ETH
        console.log("Attacker Balance: ", address(attacker).balance);
        assertEq(attacker.balance, GAME_POT);
    }
}
