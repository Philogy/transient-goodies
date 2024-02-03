// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {tuint256, tbytes32, taddress} from "../src/TransientPrimitives.sol";

/// @author philogy <https://github.com/philogy>
contract TransientPrimitivesTest is Test {
    tuint256 uint256_var;
    tbytes32 bytes32_var;
    taddress address_var;

    mapping(address => tuint256) transient_addr_to_uint;

    function test_defaultValues() public {
        assertEq(uint256_var.get(), 0);
        assertEq(bytes32_var.get(), 0);
        assertEq(address_var.get(), address(0));
    }

    function test_setUint256(uint256 value1, uint256 value2) public {
        uint256_var.set(value1);
        assertEq(uint256_var.get(), value1);
        uint256_var.set(value2);
        assertEq(uint256_var.get(), value2);
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

    function test_setAddrUintMap(address key, uint256 value) public {
        assertEq(transient_addr_to_uint[key].get(), 0);
        transient_addr_to_uint[key].set(value);
        assertEq(transient_addr_to_uint[key].get(), value);
    }
}
