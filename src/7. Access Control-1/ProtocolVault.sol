// SPDX-License-Identifier: MIT
pragma solidity ^0.4.24;

contract ProtocolVault {
    // Contract owner
    address public owner;

    function ProtocolVault() public {
        owner = msg.sender;
    }

    function withdrawETH() external {
        require(msg.sender == owner, "Not owner");
        this._sendETH(msg.sender);
    }

    function _sendETH(address to) {
        to.transfer(address(this).balance);
    }

    function() external payable {}
}
