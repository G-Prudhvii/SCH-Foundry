// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {OpenOcean} from "../../src/2.1 erc721-2/OpenOcean.sol";
import {DummyERC721} from "../../src/2.1 erc721-2/utils/DummyERC721.sol";

contract TestERC721Two is Test {
    OpenOcean marketPlace;
    DummyERC721 cutiesNFT;
    DummyERC721 booblesNFT;

    address deployer = makeAddr("deployer");
    address user1 = makeAddr("User1");
    address user2 = makeAddr("User2");
    address user3 = makeAddr("User3");

    uint256 constant CUTIES_NFT_PRICE = 5 ether;
    uint256 constant BOOBLES_NFT_PRICE = 7 ether;
    uint256 constant INITIAL_BALANCE = 100 ether;

    function setUp() public {
        vm.deal(user1, INITIAL_BALANCE);
        vm.deal(user2, INITIAL_BALANCE);
        vm.deal(user3, INITIAL_BALANCE);

        vm.startPrank(user1);
        cutiesNFT = new DummyERC721("Crypto Cuties", "CUTE", 1000);
        cutiesNFT.mintBulk(30);
        vm.stopPrank();

        assertEq(cutiesNFT.balanceOf(user1), 30);

        vm.startPrank(user3);
        booblesNFT = new DummyERC721("Rare Boobles", "BOO", 10000);
        booblesNFT.mintBulk(120);
        vm.stopPrank();

        assertEq(booblesNFT.balanceOf(user3), 120);

        // TODO: Deploy Marketplace from deployer
        vm.prank(deployer);
        marketPlace = new OpenOcean();
    }

    function testListingAndPurchasing() public {
        // TODO: User1 lists Cute NFT tokens 1-10 for 5 ETH each
        vm.startPrank(user1);
        for (uint256 i = 1; i <= 10; i++) {
            cutiesNFT.approve(address(marketPlace), i);
            marketPlace.listItem(address(cutiesNFT), i, CUTIES_NFT_PRICE);
        }
        vm.stopPrank();

        // TODO: Check that Marketplace owns 10 Cute NFTs
        assertEq(cutiesNFT.balanceOf(address(marketPlace)), 10);

        // TODO: Checks that the marketplace mapping is correct (All data is correct), check the 10th item.
        OpenOcean.Item memory lastItemCuties = marketPlace.getItem(10);

        assertEq(lastItemCuties.itemId, 10);
        assertEq(lastItemCuties.collection, address(cutiesNFT));
        assertEq(lastItemCuties.tokenId, 10);
        assertEq(lastItemCuties.price, CUTIES_NFT_PRICE);
        assertEq(lastItemCuties.seller, address(user1));
        assertEq(lastItemCuties.isSold, false);

        // TODO: User3 lists Boobles NFT tokens 1-5 for 7 ETH each
        vm.startPrank(user3);
        for (uint256 i = 1; i <= 5; i++) {
            booblesNFT.approve(address(marketPlace), i);
            marketPlace.listItem(address(booblesNFT), i, BOOBLES_NFT_PRICE);
        }
        vm.stopPrank();

        // TODO: Check that Marketplace owns 5 Booble NFTs
        assertEq(booblesNFT.balanceOf(address(marketPlace)), 5);

        // TODO: Checks that the marketplace mapping is correct (All data is correct), check the 15th item.
        OpenOcean.Item memory lastItemBoobles = marketPlace.getItem(15);

        assertEq(lastItemBoobles.itemId, 15);
        assertEq(lastItemBoobles.collection, address(booblesNFT));
        assertEq(lastItemBoobles.tokenId, 5);
        assertEq(lastItemBoobles.price, BOOBLES_NFT_PRICE);
        assertEq(lastItemBoobles.seller, address(user3));
        assertEq(lastItemBoobles.isSold, false);

        // All Purchases From User2 //
        vm.startPrank(user2);
        // TODO: Try to purchase itemId 100, should revert
        vm.expectRevert("Incorrect itemId");
        marketPlace.purchase(100);

        // TODO: Try to purchase itemId 3, without ETH, should revert
        vm.expectRevert("Insufficient price");
        marketPlace.purchase(3);

        // TODO: Try to purchase itemId 3, with ETH, should work
        marketPlace.purchase{value: CUTIES_NFT_PRICE}(3);

        // TODO: Can't purchase sold item
        vm.expectRevert("Item already sold");
        marketPlace.purchase{value: 5 ether}(3);

        // TODO: User2 owns itemId 3 -> Cuties tokenId 3
        assertEq(cutiesNFT.ownerOf(3), address(user2));

        // TODO: User1 got the right amount of ETH for the sale
        // INITIAL_BALANCE = 100 ether, cutiesNFT = 5 ether TOTAL = 105 ether
        assertEq(address(user1).balance, 105 ether);

        // TODO: Purchase itemId 11
        marketPlace.purchase{value: BOOBLES_NFT_PRICE}(11);

        // TODO: User2 owns itemId 11 -> Boobles tokenId 1
        assertEq(booblesNFT.ownerOf(1), address(user2));

        // TODO: User3 got the right amount of ETH for the sale
        // INITIAL_BALANCE = 100 ether, booblesNFT = 7 ether TOTAL = 107 ether
        assertEq(address(user3).balance, 107 ether);

        vm.stopPrank();
    }
}
