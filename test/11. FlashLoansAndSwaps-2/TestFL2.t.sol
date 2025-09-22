// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {FlashLoan} from "../../src/11. FlashLoansAndSwaps-2/FlashLoan.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";
import "../../src/interfaces/ILendingPool.sol";

// source .env
// forge test -vvv --fork-url $MAINNET_RPC_URL --fork-block-number 15969633 --mc TestFL2

contract TestFL2 is Test {
    FlashLoan private flashLoan;
    ILendingPool private lendingPool;
    IERC20 private usdc;

    // Should have $4.745M USDC on mainnet block 15969633
    //https://etherscan.io/address/0x8e5dEdeAEb2EC54d0508973a0Fccd1754586974A

    address constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // Example USDC address
    address constant LENDING_POOL_ADDRESS = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9; // Example Aave V2 Lending Pool address
    address constant USDC_WHALE = 0x8e5dEdeAEb2EC54d0508973a0Fccd1754586974A; // Replace with a test user address

    uint256 constant FLASH_LOAN_AMOUNT = 100_000_000 * 10 ** 6; // 100 Million USDC with 6 decimals
    uint256 constant AAVE_FEE = 90_000 * 10 ** 6; // 0.09% fee on 100 Million USDC

    function setUp() public {
        vm.startPrank(USDC_WHALE);
        usdc = IERC20(USDC_ADDRESS);
        flashLoan = new FlashLoan(LENDING_POOL_ADDRESS);
        vm.stopPrank();
    }

    function testGetFlashLoan() public {
        // Test the getFlashLoan function
        vm.startPrank(USDC_WHALE);
        usdc.transfer(address(flashLoan), AAVE_FEE); // Fund the contract to pay back the loan
        flashLoan.getFlashLoan(USDC_ADDRESS, FLASH_LOAN_AMOUNT);
        vm.stopPrank();
    }
}
