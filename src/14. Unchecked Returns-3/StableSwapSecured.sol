// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract StableSwap is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    address[] supportedTokens;

    constructor(address[] memory tokens) {
        for (uint256 i = 0; i < tokens.length; i++) {
            supportedTokens.push(tokens[i]);
        }
    }

    function swap(address fromToken, address toToken, uint256 amount) external nonReentrant {
        require(isSupported(fromToken, toToken), "one of the tokens (or both) are not supported");
        require(amount > 0, "amount should be bigger then 0");

        // Check liquidity
        uint256 balance = IERC20(toToken).balanceOf(address(this));
        require(balance >= amount, "Not enough liquidity");

        // Transfer
        // @audit-issue Unchecked return values
        IERC20(fromToken).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(toToken).safeTransfer(msg.sender, amount);
    }

    function isSupported(address fromToken, address toToken) public view returns (bool) {
        bool fromSupported = false;
        bool toSupported = false;

        for (uint256 i = 0; i < supportedTokens.length; i++) {
            if (fromToken == supportedTokens[i]) {
                fromSupported = true;
            }
            if (toToken == supportedTokens[i]) {
                toSupported = true;
            }
        }

        if (fromSupported && toSupported) {
            return true;
        }

        return false;
    }

    function emergencyWithdraw(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, amount);
    }
}
