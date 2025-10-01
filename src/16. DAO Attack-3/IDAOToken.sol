// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDAOToken is IERC20 {
    function snapshot() external returns (uint256 lastSnapshotId);
    function getBalanceAtSnapshot(address account, uint256 snapshotID) external view returns (uint256);
    function getTotalSupplyAtSnapshot(uint256 snapshotID) external view returns (uint256);
}
