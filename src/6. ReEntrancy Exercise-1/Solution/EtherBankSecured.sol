// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EtherBank is ReentrancyGuard {
    mapping(address => uint256) public balances;
    bool reentrant;

    modifier protected() {
        require(!reentrant, "No ReEntrancy");
        reentrant = true;
        _;
        reentrant = false;
    }

    function depositETH() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdrawETH() public nonReentrant {
        uint256 balance = balances[msg.sender];
        // Update Balance
        balances[msg.sender] = 0;

        // Send ETH
        (bool success,) = msg.sender.call{value: balance}("");
        require(success, "Withdraw failed");
    }
}
