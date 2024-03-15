// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {GuardedDeposit} from "./mocks/GuardedDeposit.sol";
import {Reenterer} from "./mocks/Reenterer.sol";

/// @author philogy <https://github.com/philogy>
contract ReentrancyGuardTest is Test {
    GuardedDeposit target;
    Reenterer attacker;

    function setUp() public {
        target = new GuardedDeposit();
        attacker = new Reenterer(address(target));
    }

    function test_mock_vulnerableWithoutGuard() public {
        uint256 value = 1 ether;
        for (uint256 i = 0; i < 10; i++) {
            hoax(vm.addr(1 + i), value);
            target.deposit{value: value}();
        }

        address trigger = makeAddr("trigger");
        hoax(trigger, value);
        attacker.deposit{value: value}();

        attacker.attack(target.vulnerableWithdraw.selector, target.vulnerableWithdraw.selector, 5);
        assertEq(address(attacker).balance, value * 5);
    }

    function test_blocksReentrancy() public {
        uint256 value = 1 ether;
        for (uint256 i = 0; i < 10; i++) {
            hoax(vm.addr(1 + i), value);
            target.deposit{value: value}();
        }

        address trigger = makeAddr("trigger");
        hoax(trigger, value);
        attacker.deposit{value: value}();

        vm.expectRevert(abi.encodeWithSignature("Reentering()"));
        attacker.attack(target.withdraw1.selector, target.withdraw1.selector, 5);

        vm.expectRevert(abi.encodeWithSignature("Reentering()"));
        attacker.attack(target.withdraw2.selector, target.withdraw2.selector, 5);

        // Cross-function reentrancy
        vm.expectRevert(abi.encodeWithSignature("Reentering()"));
        attacker.attack(target.withdraw2.selector, target.withdraw1.selector, 5);
    }
}
