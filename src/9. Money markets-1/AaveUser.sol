// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./AaveInterfaces.sol";

contract AaveUser is Ownable {
    // TODO: Complete state variables
    IPool private immutable aavePool;
    IERC20 private immutable usdc;
    IERC20 private immutable dai;

    uint256 public depositedAmount;
    uint256 public borrowedAmount;

    // TODO: Complete the constructor
    constructor(address _pool, address _usdc, address _dai) {
        aavePool = IPool(_pool);
        usdc = IERC20(_usdc);
        dai = IERC20(_dai);
    }

    // Deposit USDC in AAVE Pool
    function depositUSDC(uint256 _amount) external onlyOwner {
        // TODO: Implement this function

        // TODO: Update depositedamount state var
        depositedAmount += _amount;

        // TODO: Transfer from the sender the USDC to this contract
        usdc.transferFrom(msg.sender, address(this), _amount);

        // TODO: Supply USDC to aavePool Pool
        usdc.approve(address(aavePool), _amount);
        aavePool.supply(address(usdc), _amount, address(this), 0);
    }

    // Withdraw USDC
    function withdrawUSDC(uint256 _amount) external onlyOwner {
        // TODO: Implement this function

        // TODO: Revert if the user is trying to withdraw more than the deposited amount
        require(_amount <= depositedAmount, "Can't withdraw more than deposited amount");

        // TODO: Update depositedamount state var
        depositedAmount -= _amount;

        // TODO: Withdraw the USDC tokens, send them directly to the user
        aavePool.withdraw(address(usdc), _amount, msg.sender);
    }

    // Borrow DAI From aave, send DAI to the user (msg.sender)
    function borrowDAI(uint256 _amount) external onlyOwner {
        // TODO: Implement this function

        // TODO: Update borrowedAmmount state var
        borrowedAmount += _amount;

        // TODO: Borrow the DAI tokens in variable interest mode
        aavePool.borrow(address(dai), _amount, 2, 0, address(this));

        // TODO: Transfer DAI token to the user
        dai.transfer(msg.sender, _amount);
    }

    // Repay the borrowed DAI to AAVE
    function repayDAI(uint256 _amount) external onlyOwner {
        // TODO: Implement this function

        // TODO: Revert if the user is trying to repay more tokens that he borrowed
        require(_amount <= borrowedAmount, "You are paying more than you borrowed");

        // TODO: Update borrowedAmmount state var
        borrowedAmount -= _amount;

        // TODO: Transfer the DAI tokens from the user to this contract
        dai.transferFrom(msg.sender, address(this), _amount);

        // TODO: Approve AAVE Pool to spend the DAI tokens
        dai.approve(address(aavePool), _amount);

        // TODO: Repay the loan
        aavePool.repay(address(dai), _amount, 2, address(this));
    }
}
