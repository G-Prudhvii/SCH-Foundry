// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SimpleSmartWalletSecured {
    address public walletOwner;

    constructor() payable {
        walletOwner = msg.sender;
    }

    function transfer(address payable _to, uint256 _amount) public {
        require(msg.sender == walletOwner, "Only Owner");

        (bool sent,) = _to.call{value: _amount}("");
        require(sent, "Failed");
    }
}
