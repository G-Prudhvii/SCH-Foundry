// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Game {
    constructor() payable {}

    function play(uint256 guess) external {
        uint256 number = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, block.prevrandao)));

        if (guess == number) {
            (bool sent,) = msg.sender.call{value: address(this).balance}("");
            require(sent, "Failed to send ETH");
        }
    }
}
