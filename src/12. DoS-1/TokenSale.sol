// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenSale is ERC20("BestToken", "BST"), Ownable {
    mapping(address => uint256[]) invested;
    address[] investors;

    event DistributedTokens(address to, uint256 amount);

    function invest() public payable {
        investors.push(msg.sender);
        invested[msg.sender].push(msg.value * 5);
    }

    function distributeTokens() public onlyOwner {
        for (uint256 i = 0; i < investors.length; i++) {
            address currentInvestor = investors[i];
            uint256[] memory userInvestments = invested[currentInvestor];

            // investor => [0.0000001, 0.00000001, .....]
            for (uint256 i = 0; i < userInvestments.length; i++) {
                _mint(currentInvestor, userInvestments[i]);
                emit DistributedTokens(currentInvestor, userInvestments[i]);
            }
        }
    }

    function withdrawETH() public onlyOwner {
        bool sent = payable(msg.sender).send(address(this).balance);
        require(sent, "Failed to send Ether");
    }

    function claimable(address account, uint256 investmentID) public view returns (uint256) {
        return invested[account][investmentID];
    }
}
