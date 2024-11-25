// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import "../../src/9. Money markets-1/AaveUser.sol";
import "../../src/9. Money markets-1/AaveInterfaces.sol";

contract TestAaveUser is Test {
    address user = makeAddr("user");

    address constant AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant WHALE = 0xF977814e90dA44bFA03b6295A0616a897441aceC;

    // AAVE USDC Receipt Token
    address constant A_USDC = 0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c;

    // AAVE DAI Variable Debt Token
    address constant VARIABLE_DEBT_DAI = 0xcF8d0c70c850859266f5C338b38F9D663181C314;

    uint256 constant USER_USDC_BALANCE = 100_000 * 10 ** 6;
    uint256 constant AMOUNT_TO_DEPOSIT = 1_000 * 10 ** 6;
    uint256 constant AMOUNT_TO_BORROW = 100 ether;

    IERC20 usdc = IERC20(USDC);
    IERC20 dai = IERC20(DAI);
    IERC20 aUSDC = IERC20(A_USDC);
    IERC20 debtDAI = IERC20(VARIABLE_DEBT_DAI);
    // Whale impersonation
    address whaleSigner = address(WHALE);
    AaveUser aaveUser;

    function setUp() public {
        vm.prank(whaleSigner);
        usdc.transfer(user, USER_USDC_BALANCE);

        assertEq(usdc.balanceOf(user), USER_USDC_BALANCE);
    }

    function testMM1() public {
        // TODO: Deploy AaveUser contract
        vm.startPrank(user);
        aaveUser = new AaveUser(AAVE_POOL, USDC, DAI);

        // TODO: Approve and Deposit 1000 USDC tokens
        usdc.approve(address(aaveUser), AMOUNT_TO_DEPOSIT);
        aaveUser.depositUSDC(AMOUNT_TO_DEPOSIT);

        // TODO: Validate that the depositedAmount state var was changed
        assertEq(aaveUser.depositedAmount(), AMOUNT_TO_DEPOSIT);

        // TODO: Validate that your contract received the aUSDC tokens (receipt tokens)
        assertEq(aUSDC.balanceOf(address(aaveUser)), AMOUNT_TO_DEPOSIT);

        // TODO: borrow 100 DAI tokens
        aaveUser.borrowDAI(AMOUNT_TO_BORROW);

        // TODO: Validate that the borrowedAmount state var was changed
        assertEq(aaveUser.borrowedAmount(), AMOUNT_TO_BORROW);

        // TODO: Validate that the user received the DAI Tokens
        assertEq(dai.balanceOf(address(user)), AMOUNT_TO_BORROW);

        // TODO: Validate that your contract received the DAI variable debt tokens
        assertEq(debtDAI.balanceOf(address(aaveUser)), AMOUNT_TO_BORROW);

        // TODO: Repay all the DAI
        dai.approve(address(aaveUser), AMOUNT_TO_BORROW);
        aaveUser.repayDAI(AMOUNT_TO_BORROW);

        // TODO: Validate that the borrowedAmount state var was changed
        assertEq(aaveUser.borrowedAmount(), 0);

        // TODO: Validate that the user doesn't own the DAI tokens
        assertEq(dai.balanceOf(address(user)), 0);

        // TODO: Validate that your contract own much less DAI Variable debt tokens (less then 0.1% of borrowed amount)
        // Note: The contract still supposed to own some becuase of negative interest
        assertLt(debtDAI.balanceOf(address(aaveUser)), AMOUNT_TO_BORROW / 1000);

        // TODO: Withdraw all your USDC
        aaveUser.withdrawUSDC(AMOUNT_TO_DEPOSIT);

        // TODO: Validate that the depositedAmount state var was chaged
        assertEq(aaveUser.depositedAmount(), 0);

        // TODO: Validate that the user got the USDC tokens back
        assertEq(usdc.balanceOf(address(user)), USER_USDC_BALANCE);

        // TODO: Validate that your contract own much less aUSDC receipt tokens (less then 0.1% of deposited amount)
        // Note: The contract still supposed to own some becuase of the positive interest
        assertLt(aUSDC.balanceOf(address(aaveUser)), AMOUNT_TO_DEPOSIT / 1000);
    }
}
