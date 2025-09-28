// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IEscrowNFT is IERC721 {
    function tokenDetails(uint256) external view returns (uint256, uint256);
    function tokenCounter() external view returns (uint256);
    function mint(address _recipient, uint256 _amount, uint256 _matureTime) external returns (uint256);
    function burn(uint256 _tokenId) external;
}
