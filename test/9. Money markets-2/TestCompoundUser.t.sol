// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import "../../src/9. Money markets-2/CompoundUser.sol";
import "../../src/9. Money markets-2/CompoundInterfaces.sol";

contract TestCompoundUser is Test {
    address user = makeAddr("user");

    address constant COMPOUND_COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant WHALE = 0xF977814e90dA44bFA03b6295A0616a897441aceC;

    // Compound USDC Receipt Token
    address constant C_USDC = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;

    // Compound DAI Receipt Token
    address constant C_DAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;

    uint256 constant USER_USDC_BALANCE = 100_000 * 10 ** 6;
    uint256 constant AMOUNT_TO_DEPOSIT = 1_000 * 10 ** 6;
    uint256 constant AMOUNT_TO_BORROW = 100 ether;

    IERC20 usdc = IERC20(USDC);
    IERC20 dai = IERC20(DAI);
    cERC20 cUsdc = cERC20(C_USDC);
    cERC20 cDai = cERC20(C_DAI);

    CompoundUser cUser;

    // Whale impersonation
    address whaleSigner = address(WHALE);

    function setUp() public {
        // Transfer USDC to the user
        vm.prank(whaleSigner);
        assertTrue(usdc.transfer(user, USER_USDC_BALANCE));
        assertEq(dai.balanceOf(user), 0);
    }

    function testMM2() public {
        // TODO: Deploy CompoundUser.sol smart contract
        vm.startPrank(user);
        cUser = new CompoundUser(COMPOUND_COMPTROLLER, C_USDC, C_DAI);

        // TODO: Deposit USDC to compound
        usdc.approve(address(cUser), AMOUNT_TO_DEPOSIT);
        cUser.deposit(AMOUNT_TO_DEPOSIT);

        // TODO: Validate that the depositedAmount state var was changed
        assertEq(cUser.depositedAmount(), AMOUNT_TO_DEPOSIT);

        // TODO: Store the aUSDC tokens that were minted to the compoundUser contract in `cUSDCBalanceBefore`
        uint256 cUSDCBalanceBefore = cUsdc.balanceOf(address(cUser));

        // TODO: Validate that your contract received cUSDC tokens (receipt tokens)
        assertGt(cUSDCBalanceBefore, AMOUNT_TO_DEPOSIT);

        // TODO: Allow USDC as collateral
        cUser.allowUSDCAsCollateral();

        // TODO: Borrow 100 DAI against the deposited USDC
        cUser.borrow(AMOUNT_TO_BORROW);

        // TODO: Validate that the borrowedAmount state var was changed
        assertEq(cUser.borrowedAmount(), AMOUNT_TO_BORROW);

        // TODO: Validate that the user received the DAI Tokens
        assertEq(dai.balanceOf(address(user)), AMOUNT_TO_BORROW);

        // TODO: Repay all the borrowed DAI
        dai.approve(address(cUser), AMOUNT_TO_BORROW);
        cUser.repay(AMOUNT_TO_BORROW);

        // TODO: Validate that the borrowedAmount state var was changed
        assertEq(cUser.borrowedAmount(), 0);

        // TODO: Validate that the user doesn't own the DAI tokens
        assertEq(dai.balanceOf(address(user)), 0);

        // TODO: Withdraw all your USDC
        cUser.withdraw(AMOUNT_TO_DEPOSIT);

        // TODO: Validate that the depositedAmount state var was changed
        assertEq(cUser.depositedAmount(), 0);

        // TODO: Validate that the user got the USDC tokens back
        assertEq(usdc.balanceOf(address(user)), USER_USDC_BALANCE);

        // TODO: Validate that the majority of the cUSDC tokens (99.9%) were burned, and the contract deosn't own them
        // NOTE: There are still some cUSDC tokens left, since we accumulated positive interest
        uint256 cUSDCBalanceAfter = cUsdc.balanceOf(address(user));
        assertLt(cUSDCBalanceAfter, cUSDCBalanceBefore);
    }
}
