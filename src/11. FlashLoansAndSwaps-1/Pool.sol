// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IReceiver {
    function getEth() external payable;
}

contract Pool {
    constructor() payable {}

    function flashLoan(uint256 amount) external {
        uint256 poolBeforeBalance = address(this).balance;
        require(poolBeforeBalance >= amount, "Not enough ETH in pool");

        IReceiver(msg.sender).getEth{value: amount}();

        require(address(this).balance >= poolBeforeBalance, "Flash loan hasn't been paid back");
    }

    receive() external payable {}
}
