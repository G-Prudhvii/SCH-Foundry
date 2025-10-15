// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SelfDestruct {
    fallback() external {
        selfdestruct(payable(address(0)));
    }
}
