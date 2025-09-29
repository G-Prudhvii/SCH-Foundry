// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IWETH.sol";

interface IChocolate is IERC20 {
    function swapChocolates(address tokenIn, uint256 amountIn) external payable;
}

contract Sandwich is Ownable {
    IWETH private immutable weth;
    IChocolate private immutable chocolate;

    constructor(address _weth, address _chocolate) {
        weth = IWETH(_weth);
        chocolate = IChocolate(_chocolate);
    }

    // @dev If _isBuy is true, it buys chocolate tokens, else it sells chocolate tokens
    // @dev When buying, it sends all the received ETH to the chocolate contract
    // @dev When selling, it sends all the received chocolate tokens to the chocolate contract
    // @dev The owner of this contract should be an EOA
    function sandwich(bool _isBuy) public payable {
        if (_isBuy) {
            chocolate.swapChocolates{value: msg.value}(address(weth), msg.value);
        } else {
            uint256 chocBalance = chocolate.balanceOf(address(this));
            require(chocBalance > 0, "No chocolate tokens to sell");

            // Approve the chocolate contract to spend the tokens
            chocolate.approve(address(chocolate), chocBalance);
            chocolate.swapChocolates(address(chocolate), chocBalance);

            uint256 wethBalance = weth.balanceOf(address(this));

            // Withdraw WETH to ETH
            require(wethBalance > 0, "No WETH to withdraw");
            weth.withdraw(wethBalance);

            (bool success,) = owner().call{value: address(this).balance}("");
            require(success, "Transfer failed.");
        }
    }

    receive() external payable {}
}
