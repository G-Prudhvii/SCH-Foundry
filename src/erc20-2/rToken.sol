// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title rToken
 * @author Prudhvi
 */
// contract rToken is ERC20 {
//     // TODO: Complete this contract functionality
//     constructor(address _underlyingToken, string memory _name, string memory _symbol) ERC20(_name, _symbol) {}
// }

contract rToken is ERC20 {
    address public underlyingToken;
    address public owner;

    constructor(address _underlyingToken, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        require(_underlyingToken != address(0), "Wrong underlying token");
        underlyingToken = _underlyingToken;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyOwner {
        _burn(_from, _amount);
    }
}
