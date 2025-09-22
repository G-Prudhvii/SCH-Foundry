// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPool {
    function flashLoan(uint256 amount) external;
}

contract Receiver {
    IPool private pool;

    constructor(address poolAddress) {
        pool = IPool(poolAddress);
    }

    function executeFlashLoan(uint256 amount) external {
        pool.flashLoan(amount);
    }

    function getEth() external payable {
        // Do something with the borrowed ETH

        // Repay the loan
        (bool success,) = msg.sender.call{value: msg.value}("");
        require(success, "Repayment failed");
    }
}
