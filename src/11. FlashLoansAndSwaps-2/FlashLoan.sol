// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../interfaces/ILendingPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

contract FlashLoan {
    ILendingPool pool;

    constructor(address _pool) {
        pool = ILendingPool(_pool);
    }

    // TODO: Implement this function
    function getFlashLoan(address token, uint256 amount) external {
        console.log("Requesting flash loan of %s %s", amount / 10 ** 6, token);
        console.log("Balance before flash loan: ", IERC20(token).balanceOf(address(this)) / 10 ** 6);

        address[] memory assets = new address[](1);
        assets[0] = token;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        uint256[] memory modes = new uint256[](1);
        modes[0] = 0; // 0 means no debt (flash loan)

        address onBehalfOf = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;

        pool.flashLoan(address(this), assets, amounts, modes, onBehalfOf, params, referralCode);
    }

    // TODO: Implement this function
    function executeOperation(
        address[] memory assets,
        uint256[] memory amounts,
        uint256[] memory premiums,
        address initiator,
        bytes memory params
    ) public returns (bool) {
        require(msg.sender == address(pool), "Caller must be lending pool");

        console.log("Flash loan executed");
        console.log("Balance during flash loan: ", IERC20(assets[0]).balanceOf(address(this)) / 10 ** 6);

        // This contract now has the funds requested.
        // Your logic goes here.
        // For example, arbitrage, liquidation, etc.
        // Remember that you need to pay back the flash loan plus fees.

        console.log("Amount borrowed: ", amounts[0] / 10 ** 6);
        console.log("Flash loan fee: ", premiums[0] / 10 ** 6);

        uint256 amountOwing = amounts[0] + premiums[0];
        IERC20(assets[0]).approve(address(pool), amountOwing);

        console.log("Amount owed: ", amountOwing / 10 ** 6);
        console.log("Balance after flash loan: ", IERC20(assets[0]).balanceOf(address(this)) / 10 ** 6);

        return true;
    }
}
