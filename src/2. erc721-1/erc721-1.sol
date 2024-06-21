// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MyNFT is ERC721 {
    uint256 public nftCount;
    uint256 constant MINT_PRICE = 0.1 ether;
    uint256 constant TOTAL_SUPPLY = 10000;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function mint() external payable returns (uint256) {
        require(msg.value == MINT_PRICE, "You must send 0.1 ether to mint");
        require(nftCount < TOTAL_SUPPLY, "Too late! all NFT's were minted!");
        nftCount++;
        _mint(_msgSender(), nftCount);
        return nftCount;
    }
}
