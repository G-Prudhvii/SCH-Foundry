// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    address private _owner;

    constructor(address owner) ERC20("MyToken", "MTK") Ownable(owner) {
        // _mint(owner, 100000 * (10 ** decimals()));
        _mint(owner, 100000);
        _owner = owner;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        // _mint(to, amount * (10 ** decimals()));
        _mint(to, amount);
    }
}
