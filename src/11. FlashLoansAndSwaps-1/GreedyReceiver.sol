// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPool {
    function flashLoan(uint256 amount) external;
}

contract GreedyReceiver {
    IPool private pool;

    constructor(address poolAddress) {
        pool = IPool(poolAddress);
    }

    function executeFlashLoan(uint256 amount) external {
        pool.flashLoan(amount);
    }

    function getEth() external payable {}
}
