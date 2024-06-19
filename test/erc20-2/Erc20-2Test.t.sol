// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {rToken} from "../../src/erc20-2/rToken.sol";
import {TokensDepository} from "../../src/erc20-2/TokensDepository.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokensDepositoryTest is Test {
    TokensDepository depository;

    address AAVE_ADDRESS = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address UNI_ADDRESS = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address AAVE_HOLDER = 0x2eFB50e952580f4ff32D8d2122853432bbF2E204;
    address UNI_HOLDER = 0x193cEd5710223558cd37100165fAe3Fa4dfCDC14;
    address WETH_HOLDER = 0x741AA7CFB2c7bF2A1E7D4dA2e3Df6a56cA4131F3;

    uint256 constant INITIAL_AMOUNT = 1 ether;
    uint256 constant AAVE_AMOUNT = 15 ether;
    uint256 constant UNI_AMOUNT = 5321 ether;
    uint256 constant WETH_AMOUNT = 33 ether;

    uint256 initialAAVEBalance;
    uint256 initialUNIBalance;
    uint256 initialWETHBalance;

    address rAave;
    address rUni;
    address rWeth;

    function setUp() public {
        // TODO: Deploy your depository contract with the supported assets
        depository = new TokensDepository(AAVE_ADDRESS, UNI_ADDRESS, WETH_ADDRESS);

        vm.deal(AAVE_HOLDER, INITIAL_AMOUNT);
        vm.deal(UNI_HOLDER, INITIAL_AMOUNT);
        vm.deal(WETH_HOLDER, INITIAL_AMOUNT);

        initialAAVEBalance = IERC20(AAVE_ADDRESS).balanceOf(AAVE_HOLDER);
        initialUNIBalance = IERC20(UNI_ADDRESS).balanceOf(UNI_HOLDER);
        initialWETHBalance = IERC20(WETH_ADDRESS).balanceOf(WETH_HOLDER);

        // TODO: Load receipt tokens into objects under `this` (e.g this.rAve)
        rAave = address(depository.rTokens(AAVE_ADDRESS));
        rUni = address(depository.rTokens(UNI_ADDRESS));
        rWeth = address(depository.rTokens(WETH_ADDRESS));
    }

    function testDepositsAndWithdraws() public {
        // TODO: Deposit Tokens
        // 15 AAVE from AAVE Holder
        vm.startPrank(AAVE_HOLDER);
        IERC20(AAVE_ADDRESS).approve(address(depository), AAVE_AMOUNT);
        depository.deposit(AAVE_ADDRESS, AAVE_AMOUNT);
        vm.stopPrank();

        // 5231 UNI from UNI Holder
        vm.startPrank(UNI_HOLDER);
        IERC20(UNI_ADDRESS).approve(address(depository), UNI_AMOUNT);
        depository.deposit(UNI_ADDRESS, UNI_AMOUNT);
        vm.stopPrank();

        // 33 WETH from WETH Holder
        vm.startPrank(WETH_HOLDER);
        IERC20(WETH_ADDRESS).approve(address(depository), WETH_AMOUNT);
        depository.deposit(WETH_ADDRESS, WETH_AMOUNT);
        vm.stopPrank();

        // TODO: Check that the tokens were sucessfuly transfered to the depository
        assertEq(IERC20(AAVE_ADDRESS).balanceOf(address(depository)), AAVE_AMOUNT);
        assertEq(IERC20(UNI_ADDRESS).balanceOf(address(depository)), UNI_AMOUNT);
        assertEq(IERC20(WETH_ADDRESS).balanceOf(address(depository)), WETH_AMOUNT);

        // TODO: Check that the right amount of receipt tokens were minted
        assertEq(IERC20(rAave).balanceOf(AAVE_HOLDER), AAVE_AMOUNT);
        assertEq(IERC20(rUni).balanceOf(UNI_HOLDER), UNI_AMOUNT);
        assertEq(IERC20(rWeth).balanceOf(WETH_HOLDER), WETH_AMOUNT);
        // }

        // function testWithdraws() public {
        // TODO: Withdraw ALL the Tokens
        vm.prank(AAVE_HOLDER);
        depository.withdraw(AAVE_ADDRESS, AAVE_AMOUNT);

        vm.prank(UNI_HOLDER);
        depository.withdraw(UNI_ADDRESS, UNI_AMOUNT);

        vm.prank(WETH_HOLDER);
        depository.withdraw(WETH_ADDRESS, WETH_AMOUNT);

        // TODO: Check that the right amount of tokens were withdrawn (depositors got back the assets)
        assertEq(IERC20(AAVE_ADDRESS).balanceOf(AAVE_HOLDER), initialAAVEBalance);
        assertEq(IERC20(UNI_ADDRESS).balanceOf(UNI_HOLDER), initialUNIBalance);
        assertEq(IERC20(WETH_ADDRESS).balanceOf(WETH_HOLDER), initialWETHBalance);

        // TODO: Check that the right amount of receipt tokens were burned
        assertEq(IERC20(rAave).balanceOf(AAVE_HOLDER), 0);
        assertEq(IERC20(rUni).balanceOf(UNI_HOLDER), 0);
        assertEq(IERC20(rWeth).balanceOf(WETH_HOLDER), 0);
    }
}
