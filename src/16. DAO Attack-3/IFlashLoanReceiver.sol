// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IFlashLoanReceiver {
    function callBack(uint256 borrowAmount) external;
}
