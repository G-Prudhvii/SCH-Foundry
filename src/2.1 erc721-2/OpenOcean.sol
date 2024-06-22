// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract OpenOcean {
    uint256 public constant MAX_PRICE = 100 ether;

    struct Item {
        uint256 itemId;
        address collection;
        uint256 tokenId;
        uint256 price;
        address payable seller;
        bool isSold;
    }

    uint256 public itemsCounter;
    mapping(uint256 itemId => Item) public listedItems;

    // constructor() {}

    function listItem(address _collection, uint256 _tokenId, uint256 _price) public {
        require(_collection != address(0), "Invalid collection contract");
        require(_price > 0 && _price <= MAX_PRICE, "Invalid price");

        itemsCounter += 1;
        IERC721(_collection).transferFrom(msg.sender, address(this), _tokenId);
        listedItems[itemsCounter] = Item(itemsCounter, _collection, _tokenId, _price, payable(msg.sender), false);
    }

    function purchase(uint256 _itemId) external payable {
        require(_itemId != 0 && _itemId <= itemsCounter, "Incorrect itemId");
        require(listedItems[_itemId].isSold == false, "Item already sold");
        require(msg.value == listedItems[_itemId].price, "Insufficient price");

        listedItems[_itemId].isSold = true;

        IERC721(listedItems[_itemId].collection).transferFrom(address(this), msg.sender, listedItems[_itemId].tokenId);

        (bool success,) = listedItems[_itemId].seller.call{value: msg.value}("");
        require(success, "Transfer failed");
    }

    function getItem(uint256 _itemId) external view returns (Item memory) {
        return listedItems[_itemId];
    }
}
