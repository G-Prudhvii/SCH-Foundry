// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/11. FlashLoansAndSwaps-3/FlashSwap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestFL3 is Test {
    FlashSwap flashSwap;
    IERC20 usdc;

    address constant USDC_TOKEN = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDC_WETH_PAIR = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;
    address constant USDC_WHALE = 0x8e5dEdeAEb2EC54d0508973a0Fccd1754586974A;

    uint256 constant AMOUNT_TO_BORROW = 40_000_000 * 10 ** 6; // 40_000_000 USDC with 6 decimals

    // Uniswap V2 fee is 0.3%, so we need to pay back the borrowed amount + 0.3%
    uint256 constant FEE = (AMOUNT_TO_BORROW * 3) / 997 + 1; // Adding 1 to round up
    uint256 constant AMOUNT_TO_REPAY = AMOUNT_TO_BORROW + FEE;

    function setUp() public {
        usdc = IERC20(USDC_TOKEN);

        // Deploy the FlashSwap contract
        // Impersonate the USDC whale to fund the FlashSwap contract if needed
        vm.prank(USDC_WHALE);
        flashSwap = new FlashSwap(USDC_WETH_PAIR);
    }

    function testFlashLoan() public {
        // Test the executeFlashSwap function
        // TODO: Send USDC to contract for fees
        vm.prank(USDC_WHALE);
        usdc.transfer(address(flashSwap), FEE); // Fund the contract with the fee amount

        // Execute successfully a flash swap of 40,000,000 USDC
        flashSwap.executeFlashSwap(USDC_TOKEN, AMOUNT_TO_BORROW);
    }
}
