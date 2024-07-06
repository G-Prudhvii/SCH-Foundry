// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {CryptoEmpireGame} from "../../src/6. ReEntrancy Exercise-4/CryptoEmpireGame.sol";
import {CryptoEmpireToken} from "../../src/6. ReEntrancy Exercise-4/CryptoEmpireToken.sol";
import {Attack} from "../../src/6. ReEntrancy Exercise-4/Attack.sol";

contract TestCryptoEmpireGame is Test {
    CryptoEmpireGame game;
    CryptoEmpireToken token;
    Attack attackContract;

    address deployer = makeAddr("deployer");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address attacker = makeAddr("attacker");

    function setUp() public {
        vm.startPrank(deployer);
        token = new CryptoEmpireToken();
        game = new CryptoEmpireGame(address(token));

        // Giving 1 NFT to each user
        token.mint(user1, 1, CryptoEmpireToken.NftId.HELMET);
        token.mint(user2, 1, CryptoEmpireToken.NftId.SHIELD);
        token.mint(attacker, 1, CryptoEmpireToken.NftId.ARMOUR);

        // The CryptoEmpire game gained many users already and has some NFTs either staked or listed in it
        for (uint256 i = 0; i <= 5; i++) {
            token.mint(address(game), 20, CryptoEmpireToken.NftId(i));
        }
    }

    function testExploit() public {
        // Deploy malicious contract
        vm.startPrank(attacker);
        attackContract = new Attack(address(token), address(game));
        token.safeTransferFrom(attacker, address(attackContract), 2, 1, "");
        attackContract.exploit();
        vm.stopPrank();

        // Attacker stole all the tokens from the game contract
        assertEq(token.balanceOf(attacker, 2), 21);
        assertEq(token.balanceOf(address(game), 2), 0);
    }
}
