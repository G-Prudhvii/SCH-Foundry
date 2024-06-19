// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {rToken} from "./rToken.sol";

/**
 * @title TokensDepository
 * @author Prudhvi
 */
contract TokensDepository {
    mapping(address => IERC20) public tokens;
    mapping(address => rToken) public rTokens;

    constructor(address _aave, address _uni, address _weth) {
        tokens[_aave] = IERC20(_aave);
        tokens[_uni] = IERC20(_uni);
        tokens[_weth] = IERC20(_weth);

        // Deploy tokens
        rTokens[_aave] = new rToken(_aave, "Receipt AAVE", "rAave");
        rTokens[_uni] = new rToken(_uni, "Receipt UNI", "rUni");
        rTokens[_weth] = new rToken(_weth, "Receipt WETH", "rWeth");
    }

    modifier isSupported(address _token) {
        require(address(tokens[_token]) != address(0), "Token is not supported");
        _;
    }

    function deposit(address _token, uint256 _amount) external isSupported(_token) {
        bool success = tokens[_token].transferFrom(msg.sender, address(this), _amount);
        require(success, "transfer failed");

        rTokens[_token].mint(msg.sender, _amount);
    }

    function withdraw(address _token, uint256 _amount) external isSupported(_token) {
        rTokens[_token].burn(msg.sender, _amount);

        bool success = tokens[_token].transfer(msg.sender, _amount);
        require(success, "transfer failed");
    }
}
