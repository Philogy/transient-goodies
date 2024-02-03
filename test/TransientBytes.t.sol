// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {TransientBytes} from "../src/TransientBytesLib.sol";

/// @author philogy <https://github.com/philogy>
contract TransientBytesTest is Test {
    TransientBytes data;

    uint256 internal constant MAX_LENGTH = type(uint32).max;

    function test_defaultEmpty() public {
        assertEq(data.get(), "");
        assertEq(data.length(), 0);
    }

    function test_setMem(bytes memory inner) public {
        vm.assume(inner.length <= MAX_LENGTH);
        data.set(inner);
        assertEq(data.get(), inner);
        assertEq(data.length(), inner.length);
        data.clear();
        assertEq(data.get(), "");
        assertEq(data.length(), 0);
    }

    function test_setCd(bytes calldata inner) public {
        vm.assume(inner.length <= MAX_LENGTH);
        data.setCd(inner);
        assertEq(data.get(), inner);
        assertEq(data.length(), inner.length);
        data.clear();
        assertEq(data.get(), "");
        assertEq(data.length(), 0);
    }

    function test_multipleSetMemNoClear(bytes memory inner1, bytes memory inner2) public {
        vm.assume(inner1.length <= MAX_LENGTH);
        vm.assume(inner2.length <= MAX_LENGTH);

        data.set(inner1);
        assertEq(data.get(), inner1);
        data.set(inner2);
        assertEq(data.get(), inner2);
    }

    function test_multipleSetCdNoClear(bytes calldata inner1, bytes calldata inner2) public {
        vm.assume(inner1.length <= MAX_LENGTH);
        vm.assume(inner2.length <= MAX_LENGTH);

        data.setCd(inner1);
        assertEq(data.get(), inner1);
        data.setCd(inner2);
        assertEq(data.get(), inner2);
    }
}
