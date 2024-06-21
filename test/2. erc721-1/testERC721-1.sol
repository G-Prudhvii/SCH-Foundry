// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {MyNFT} from "../../src/2. erc721-1/erc721-1.sol";
import {Test} from "forge-std/Test.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestMyNFT is Test {
    MyNFT myNFT;
    uint256 constant DEPLOYER_MINT = 5;
    uint256 constant USER1_MINT = 3;
    address deployer = makeAddr("deployer");
    address user1 = makeAddr("User1");
    address user2 = makeAddr("User2");

    function setUp() public {
        // TODO: Contract deployment
        myNFT = new MyNFT("MyNFT", "MNFT");

        vm.deal(deployer, 1 ether);
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
    }

    function testMinting() public {
        // TODO: Deployer mints
        // Deployer should own token ids 1-5
        vm.startPrank(deployer);
        for (uint256 i = 0; i < DEPLOYER_MINT; i++) {
            myNFT.mint{value: 0.1 ether}();
        }
        vm.stopPrank();

        // TODO: User 1 mints
        // User1 should own token ids 6-8
        vm.startPrank(user1);
        for (uint256 i = 0; i < USER1_MINT; i++) {
            myNFT.mint{value: 0.1 ether}();
        }
        vm.stopPrank();

        // TODO: Check Minting
        assertEq(myNFT.balanceOf(deployer), DEPLOYER_MINT);
        assertEq(myNFT.balanceOf(user1), USER1_MINT);
        assertEq(myNFT.balanceOf(user2), 0);

        // TODO: Transfering tokenId 6 from user1 to user2
        vm.prank(user1);
        myNFT.transferFrom(user1, user2, 6);

        // TODO: Checking that user2 owns tokenId 6
        assertEq(myNFT.ownerOf(6), user2);

        // TODO: Deployer approves User1 to spend tokenId 3
        vm.prank(deployer);
        myNFT.approve(user1, 3);

        // TODO: Test that User1 has approval to spend TokenId 3
        assertEq(myNFT.getApproved(3), user1);

        // TODO: Use approval and transfer tokenId 3 from deployer to User1
        vm.prank(user1);
        myNFT.transferFrom(deployer, user1, 3);

        // TODO: Checking that user1 owns tokenId 3
        assertEq(myNFT.ownerOf(3), user1);

        // TODO: Checking balances after transfer
        // Deployer: 5 minted, 1 sent, 0 received
        assertEq(myNFT.balanceOf(deployer), 4);

        // User1: 3 minted, 1 sent, 1 received
        assertEq(myNFT.balanceOf(user1), 3);

        // User2: 0 minted, 0 sent, 1 received
        assertEq(myNFT.balanceOf(user2), 1);
    }
}
