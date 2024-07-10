// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, stdError} from "forge-std/Test.sol";
import {TransientPrimitivesLib, tuint256, tint256, tbytes32, taddress} from "../src/TransientPrimitives.sol";

/// @author philogy <https://github.com/philogy>
contract TransientPrimitivesTest is Test {
    tuint256 uint256_var;
    tint256 int256_var;
    tbytes32 bytes32_var;
    taddress address_var;

    mapping(address => tuint256) transient_addr_to_uint;

    function test_defaultValues() public {
        assertEq(uint256_var.get(), 0);
        assertEq(int256_var.get(), 0);
        assertEq(bytes32_var.get(), 0);
        assertEq(address_var.get(), address(0));
    }

    function test_setUint256(uint256 value1, uint256 value2) public {
        uint256_var.set(value1);
        assertEq(uint256_var.get(), value1);
        uint256_var.set(value2);
        assertEq(uint256_var.get(), value2);
    }

    function test_setInt256(int256 value1, int256 value2) public {
        int256_var.set(value1);
        assertEq(int256_var.get(), value1);
        int256_var.set(value2);
        assertEq(int256_var.get(), value2);
    }

    function test_setBytes32(bytes32 value1, bytes32 value2) public {
        bytes32_var.set(value1);
        assertEq(bytes32_var.get(), value1);
        bytes32_var.set(value2);
        assertEq(bytes32_var.get(), value2);
    }

    function test_setAddress(address value1, address value2) public {
        address_var.set(value1);
        assertEq(address_var.get(), value1);
        address_var.set(value2);
        assertEq(address_var.get(), value2);
    }

    function test_increaseUint256(uint256 start, uint256 increase) public {
        increase = bound(increase, 0, type(uint256).max - start);
        uint256_var.set(start);
        assertEq(start + increase, uint256_var.inc(increase));
        assertEq(start + increase, uint256_var.get());
    }

    function test_increaseUint256RevertsOnOverflow(uint256 start, uint256 increase) public {
        start = bound(start, 1, type(uint256).max);
        increase = bound(increase, type(uint256).max - start + 1, type(uint256).max);
        uint256_var.set(start);
        vm.expectRevert(stdError.arithmeticError);
        uint256_var.inc(increase);
    }

    function test_signedUint256Increase(uint256 start, int256 delta) public {
        uint256 absDelta;
        unchecked {
            absDelta = delta < 0 ? uint256(-delta) : uint256(delta);
        }
        bool overflows = delta < 0 ? absDelta > start : type(uint256).max - start < absDelta;

        uint256_var.set(start);
        if (overflows) {
            vm.expectRevert(TransientPrimitivesLib.ArithmeticOverflowUnderflow.selector);
            uint256_var.inc(delta);
        } else {
            uint256_var.inc(delta);
            uint256 end = uint256_var.get();
            if (delta < 0) {
                assertEq(end, start - absDelta);
            } else {
                assertEq(end, start + absDelta);
            }
        }
    }

    function test_signedUint256Decrease(uint256 start, int256 delta) public {
        uint256 absDelta;
        unchecked {
            absDelta = delta < 0 ? uint256(-delta) : uint256(delta);
        }
        bool overflows = delta < 0 ? type(uint256).max - start < absDelta : absDelta > start;

        uint256_var.set(start);
        if (overflows) {
            vm.expectRevert(TransientPrimitivesLib.ArithmeticOverflowUnderflow.selector);
            uint256_var.dec(delta);
        } else {
            uint256_var.dec(delta);
            uint256 end = uint256_var.get();
            if (delta < 0) {
                assertEq(end, start + absDelta);
            } else {
                assertEq(end, start - absDelta);
            }
        }
    }

    function test_decreaseUint256(uint256 start, uint256 decrease) public {
        decrease = bound(decrease, 0, start);
        uint256_var.set(start);
        assertEq(start - decrease, uint256_var.dec(decrease));
        assertEq(start - decrease, uint256_var.get());
    }

    function test_decreaseUint256RevertsOnUnderflow(uint256 start, uint256 increase) public {
        start = bound(start, 0, type(uint256).max - 1);
        increase = bound(increase, start + 1, type(uint256).max);
        uint256_var.set(start);
        vm.expectRevert(stdError.arithmeticError);
        uint256_var.dec(increase);
    }

    function test_increaseInt256(int256 start, int256 change) public {
        int256 upperBound = start <= 0 ? type(int256).max : type(int256).max - start;
        int256 lowerBound = start >= 0 ? type(int256).min : type(int256).min - start;
        change = bound(change, lowerBound, upperBound);
        int256_var.set(start);
        assertEq(start + change, int256_var.inc(change));
        assertEq(start + change, int256_var.get());
    }

    function test_increaseInt256RevertsOnOverflow(int256 start, int256 change) public {
        // Ensure `start` is any non-zero number.
        start = int256(bound(uint256(start), 1, type(uint256).max));
        assertTrue(start != 0);
        // Guarantee overflow.
        int256 lowerBound = start > 0 ? type(int256).max - start + 1 : type(int256).min;
        int256 upperBound = start < 0 ? type(int256).min - start - 1 : type(int256).max;
        change = bound(change, lowerBound, upperBound);
        int256_var.set(start);
        vm.expectRevert(stdError.arithmeticError);
        int256_var.inc(change);
    }

    function test_decreaseInt256(int256 start, int256 change) public {
        int256 upperBound = start >= 0 ? type(int256).max : start - type(int256).min;
        int256 lowerBound = start < 0 ? type(int256).min : start - type(int256).max;
        change = bound(change, lowerBound, upperBound);
        int256_var.set(start);
        assertEq(start - change, int256_var.dec(change));
        assertEq(start - change, int256_var.get());
    }

    function test_decreaseInt256RevertsOnUnderflow(int256 start, int256 change) public {
        // Ensure `start` is not 0 or -1.
        start = int256(bound(uint256(start), 1, type(uint256).max - 1));
        int256 upperBound = start >= 0 ? start - type(int256).max - 1 : type(int256).max;
        int256 lowerBound = start < 0 ? start - type(int256).min + 1 : type(int256).min;
        change = bound(change, lowerBound, upperBound);
        int256_var.set(start);
        vm.expectRevert(stdError.arithmeticError);
        int256_var.dec(change);
    }

    function test_setAddrUintMap(address key, uint256 value) public {
        assertEq(transient_addr_to_uint[key].get(), 0);
        transient_addr_to_uint[key].set(value);
        assertEq(transient_addr_to_uint[key].get(), value);
    }
}
