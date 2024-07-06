// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract EtherBank {
    mapping(address => uint256) public balances;

    function depositETH() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdrawETH() public {
        uint256 balance = balances[msg.sender];

        // Send ETH
        (bool success,) = msg.sender.call{value: balance}("");
        require(success, "Withdraw failed");

        // Update Balance
        balances[msg.sender] = 0;
    }
}
