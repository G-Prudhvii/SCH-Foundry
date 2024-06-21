// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract OpenOcean {
    uint256 constant maxPrice = 100 ether;

    struct Item {
        uint256 itemId;
        address collectionContract;
        uint256 tokenId;
        uint256 price;
        address payable seller;
        bool isSold;
    }

    uint256 public itemsCounter;
    mapping(uint256 itemId => Item) listedItems;

    // constructor() {}

    function listItem(address _collection, uint256 _tokenId, uint256 _price) public {
        require(_collection != address(0), "Invalid collection contract");
        require(_price > 0 && _price <= maxPrice, "Invalid price");

        itemsCounter += 1;
        IERC721(_collection).transferFrom(msg.sender, address(this), _tokenId);
        listedItems[itemsCounter] = Item(itemsCounter, _collection, _tokenId, _price, payable(msg.sender), false);
    }

    function purchase(uint256 _itemId) external payable {
        require(listedItems[_itemId].itemId == _itemId, "Item not found");
        require(listedItems[_itemId].isSold == false, "Item already sold");
        require(msg.value >= listedItems[_itemId].price, "Insufficient price");

        listedItems[_itemId].isSold = true;
        IERC721(listedItems[_itemId].collectionContract).transferFrom(
            address(this), msg.sender, listedItems[_itemId].tokenId
        );
        (bool success,) = listedItems[_itemId].seller.call{value: msg.value}("");
        require(success, "Transfer failed");
    }

    function getItem(uint256 _itemId) external view returns (Item memory) {
        return listedItems[_itemId];
    }
}
