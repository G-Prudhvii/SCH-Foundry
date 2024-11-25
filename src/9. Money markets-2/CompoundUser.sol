// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CompoundInterfaces.sol";

contract CompoundUser is Ownable {
    IComptroller private comptroller;

    IERC20 private usdc;
    IERC20 private dai;

    cERC20 private cUsdc;
    cERC20 private cDai;

    uint256 public depositedAmount; // In USDC
    uint256 public borrowedAmount; // In DAI

    // TODO: Implement the constructor
    constructor(address _comptroller, address _cUsdc, address _cDai) {
        // TODO: Set the comptroller, cUsdc, and cDai contracts
        comptroller = IComptroller(_comptroller);
        cUsdc = cERC20(_cUsdc);
        cDai = cERC20(_cDai);

        // TODO: Set the usdc, and dai contract (retrieve from cToken contracts)
        usdc = IERC20(cUsdc.underlying());
        dai = IERC20(cDai.underlying());
    }

    // Deposit USDC to Compound
    function deposit(uint256 _amount) external onlyOwner {
        // TODO: Implement this function

        // TODO: Update depositedAmount state var
        depositedAmount += _amount;

        // TODO: Transfer the USDC from the user to this smart contract
        usdc.transferFrom(msg.sender, address(this), _amount);

        // TODO: Approve the cUsdc contract to spend our USDC tokens
        usdc.approve(address(cUsdc), _amount);

        // TODO: Deposit USDC tokens (mint cUSDC tokens)
        cUsdc.mint(_amount);
    }

    // Allow the deposited USDC to be used as collateral, interact with the Comptroller contract
    function allowUSDCAsCollateral() external onlyOwner {
        // TODO: Implement this function

        // TODO: Use the comptroller `enterMarkets` function to set the usdc as collateral
        address[] memory markets = new address[](1);
        markets[0] = address(cUsdc);
        comptroller.enterMarkets(markets);
    }

    // Withdraw deposited USDC from Compound
    function withdraw(uint256 _amount) external onlyOwner {
        // TODO: Implement this function

        // TODO: Revert if the user is trying to withdraw more than he deposited
        require(_amount <= depositedAmount, "Trying to withdraw more than the deposited amount");

        // TODO: Update depositedAmount amount state var
        depositedAmount -= _amount;

        // TODO: Withdraw the USDC tokens
        cUsdc.redeemUnderlying(_amount);

        // TODO: Transfer USDC token to the user
        usdc.transfer(msg.sender, _amount);
    }

    // Borrow DAI from Compound
    function borrow(uint256 _amount) external {
        // TODO: Implement this function

        // TODO: Update borrowedAmount state var
        borrowedAmount += _amount;

        // TODO: Borrow DAI
        cDai.borrow(_amount);

        // TODO: Send DAI to the user
        dai.transfer(msg.sender, _amount);
    }

    // Repay the borrowed DAI
    function repay(uint256 _amount) external onlyOwner {
        // TODO: Implement this function

        // TODO: Revert if the user is trying to repay more tokens than he borrowed
        require(_amount <= borrowedAmount, "Trying to pay more than the borrowed amount");

        // TODO: Update borrowedAmount state var
        borrowedAmount -= _amount;

        // TODO: Transfer the DAI tokens from the user to this contract
        dai.transferFrom(msg.sender, address(this), _amount);

        // TODO: Approve Compound cToken contract to spend the DAI tokens
        dai.approve(address(cDai), _amount);

        // TODO: Repay the loan
        cDai.repayBorrow(_amount);
    }
}
