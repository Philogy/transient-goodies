// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {TransientBytes} from "../src/TransientBytesLib.sol";

/// @author philogy <https://github.com/philogy>
contract TransientBytesTest is Test {
    TransientBytes tbytes;

    uint256 internal constant MAX_LENGTH = type(uint32).max;

    function test_defaultEmpty() public {
        assertEq(tbytes.get(), "");
        assertEq(tbytes.length(), 0);
    }

    function test_setMem(bytes memory inner) public {
        vm.assume(inner.length <= MAX_LENGTH);
        tbytes.set(inner);
        assertEq(tbytes.get(), inner);
        assertEq(tbytes.length(), inner.length);
        tbytes.agus();
        assertEq(tbytes.get(), "");
        assertEq(tbytes.length(), 0);
    }

    function test_setCd(bytes calldata inner) public {
        vm.assume(inner.length <= MAX_LENGTH);
        tbytes.setCd(inner);
        assertEq(tbytes.get(), inner);
        assertEq(tbytes.length(), inner.length);
        tbytes.agus();
        assertEq(tbytes.get(), "");
        assertEq(tbytes.length(), 0);
    }

    function test_multipleSetMemNoAgus(bytes memory inner1, bytes memory inner2) public {
        vm.assume(inner1.length <= MAX_LENGTH);
        vm.assume(inner2.length <= MAX_LENGTH);

        tbytes.set(inner1);
        assertEq(tbytes.get(), inner1);
        tbytes.set(inner2);
        assertEq(tbytes.get(), inner2);
    }

    function test_multipleSetCdNoAgus(bytes calldata inner1, bytes calldata inner2) public {
        vm.assume(inner1.length <= MAX_LENGTH);
        vm.assume(inner2.length <= MAX_LENGTH);

        tbytes.setCd(inner1);
        assertEq(tbytes.get(), inner1);
        tbytes.setCd(inner2);
        assertEq(tbytes.get(), inner2);
    }
    }
}
