// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../interfaces/IPair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

contract FlashSwap {
    IPair pair;
    address token;

    constructor(address _pair) {
        pair = IPair(_pair);
    }

    // TODO: Implement this function
    function executeFlashSwap(address _token, uint256 _amount) external {
        console.log("Contract's token balance before flash swap:", IERC20(_token).balanceOf(address(this)) / 10 ** 6);

        token = _token;

        if (_token != pair.token0() && _token != pair.token1()) {
            revert("Invalid token address");
        }

        if (_token == pair.token0()) {
            pair.swap(_amount, 0, address(this), bytes(" "));
        } else {
            pair.swap(0, _amount, address(this), bytes(" "));
        }
    }

    // TODO: Implement this function
    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        require(msg.sender == address(pair), "Unauthorized");
        require(sender == address(this), "Not from this contract");
        console.log("In uniswapV2Call");
        console.log("Contract's token balance during flash swap:", IERC20(token).balanceOf(address(this)) / 10 ** 6);

        uint256 amountToken = amount0 == 0 ? amount1 : amount0;
        uint256 fee = (amountToken * 3) / 997 + 1;
        uint256 amountToRepay = amountToken + fee;

        console.log("Amount to repay:", amountToRepay / 10 ** 6);

        // Here you can add your custom logic using the borrowed amount
        // For simplicity, we will just repay the flash swap immediately

        IERC20(token).transfer(address(pair), amountToRepay);
        console.log(
            "Contract's token balance after repaying flash swap:", IERC20(token).balanceOf(address(this)) / 10 ** 6
        );
        console.log("Flash swap repaid");
    }
}
