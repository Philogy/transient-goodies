// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {stdError} from "forge-std/StdError.sol";
import {Multicallable} from "./mocks/Multicallable.sol";

/// @author philogy <https://github.com/philogy>
contract PayableMulticallableTest is Test {
    Multicallable multicall = new Multicallable();

    function test_preventsSimpleValueDoubleSpend() public {
        address attacker = makeAddr("attacker");
        uint256 amount = 3 ether;
        hoax(attacker, amount);
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeCall(multicall.deposit, (amount));
        data[1] = abi.encodeCall(multicall.deposit, (amount));
        vm.expectRevert(stdError.arithmeticError);
        multicall.multicall{value: amount}(true, data);
    }

    function test_allowsNormalMulticall() public {
        address user = makeAddr("user");
        hoax(user, 5 ether);
        bytes[] memory data = new bytes[](3);
        data[0] = abi.encodeCall(multicall.deposit, (2 ether));
        data[1] = abi.encodeCall(multicall.deposit, (2.9 ether));
        data[2] = abi.encodeCall(multicall.returnRemainder, ());
        multicall.multicall{value: 5 ether}(true, data);

        assertEq(multicall.balanceOf(user), 4.9 ether);
        assertEq(user.balance, 0.1 ether);
    }

    function test_allowsIndividualRevert() public {
        address user = makeAddr("user");
        hoax(user, 3 ether);
        bytes[] memory data = new bytes[](3);
        data[0] = abi.encodeCall(multicall.deposit, (1 ether));
        data[1] = abi.encodeCall(multicall.deposit, (2.1 ether));
        data[2] = abi.encodeCall(multicall.deposit, (1 ether));
        multicall.multicall{value: 3 ether}(false, data);

        assertEq(multicall.balanceOf(user), 2 ether);
    }

    function test_returnResetsValue() public {
        address user = makeAddr("user");
        hoax(user, 5 ether);
        bytes[] memory data = new bytes[](3);
        data[0] = abi.encodeCall(multicall.deposit, (2 ether));
        data[1] = abi.encodeCall(multicall.deposit, (2.9 ether));
        data[2] = abi.encodeCall(multicall.returnRemainder, ());
        multicall.multicall{value: 5 ether}(true, data);

        assertEq(multicall.balanceOf(user), 4.9 ether);
        assertEq(user.balance, 0.1 ether);
    }

    function test_standalonePaybable() public {
        address user = makeAddr("user");
        uint256 amount = 3.238 ether;
        hoax(user, amount);
        multicall.deposit{value: amount}(amount);

        assertEq(multicall.balanceOf(user), amount);
    }
}
