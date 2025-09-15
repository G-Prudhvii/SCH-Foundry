// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/12. DoS-4/GalacticGorillas.sol";

contract TestDoS4 is Test {
    GalacticGorillas public nft;

    uint256 public constant MINT_PRICE = 1 ether;

    address public deployer = makeAddr("deployer");
    address public user = makeAddr("user");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        // Deploy the contract
        vm.prank(deployer);
        nft = new GalacticGorillas();

        // Fund the users
        vm.deal(user, 100 ether);
        vm.deal(attacker, 2.5 ether);
    }

    function testDoS4SuccessMint() public {
        uint256 deployerBalanceBefore = deployer.balance;

        vm.prank(user);
        nft.mint{value: MINT_PRICE * 2}(2);

        assertTrue(nft.balanceOf(user) == 2);
        assertTrue(nft.ownerOf(1) == user);
        assertTrue(nft.ownerOf(2) == user);
        assertTrue(nft.totalSupply() == 2);

        uint256 deployerBalanceAfter = deployer.balance;
        assertTrue(deployerBalanceAfter - deployerBalanceBefore == MINT_PRICE * 2);
    }

    function testDoS4FailureMint() public {
        vm.startPrank(user);
        vm.expectRevert();
        nft.mint(20);

        vm.expectRevert(bytes("not enough ETH"));
        nft.mint{value: MINT_PRICE * 1}(2); // Sending 1 ether instead of 2 ether

        nft.mint{value: MINT_PRICE * 2}(2); // Correct minting of 2 NFTs
        vm.expectRevert(bytes("exceeded MAX_PER_WALLET"));
        nft.mint{value: MINT_PRICE * 4}(4); // Trying to mint 4 more NFTs (total 6, exceeding the limit of 5)
        vm.stopPrank();
    }

    function testDoS4Paused() public {
        vm.startPrank(user);
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        nft.pause(true);
        vm.stopPrank();

        vm.startPrank(deployer);
        nft.pause(true);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert(bytes("contract is paused"));
        nft.mint{value: 5 ether}(5);
        vm.stopPrank();

        vm.startPrank(deployer);
        nft.pause(false);
        vm.stopPrank();

        vm.startPrank(user);
        nft.mint{value: MINT_PRICE}(1);
        assertTrue(nft.balanceOf(user) == 1);
        vm.stopPrank();
    }

    function testDoS4Attack() public {
        vm.prank(user);
        nft.mint{value: MINT_PRICE * 3}(3);

        vm.startPrank(attacker);
        nft.mint{value: MINT_PRICE * 2}(2);
        nft.burn(4);
        vm.stopPrank();

        assertTrue(nft.totalSupply() == 4);

        vm.startPrank(user);
        vm.expectRevert();
        nft.mint{value: MINT_PRICE * 2}(2);
        vm.stopPrank();
    }
}
