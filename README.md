# Transient Goodies

As of 0.8.24 [solc](https://github.com/ethereum/solidity) does not grant access to a `storage`-type
specifier to be able to easily define transient storage data structures. This library is meant to be a
collection of various transient storage helpers and data structures.

Note that under the hood most of the transient types in this library are implemented as structs with
custom library methods mapped onto them. This means they will receive unique slots and are by
default composable into mappings and other structs. When defining a custom struct you
can also mix transient and persistent storage data. However it's important to note that **variables
defined as `public` will not create valid getters**, this is because Solidity will default to
reading the underlying storage struct and always default to 0.


## [Transient Primitives (`uint256`, `bytes32`, `address`)](./src/TransientPrimitives.sol)

Mimics the main 3 solidity primitive types (`uint256`, `bytes32`, `address`) but has them use
EIP-1153 transient storage.


Usage (taken from [`TransientPrimitives.t.sol`](./test/TransientPrimitives.t.sol)):

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {tuint256, tbytes32, taddress} from "../src/TransientPrimitives.sol";

/// @author philogy <https://github.com/philogy>
contract TransientPrimitivesTest is Test {
    // Definable as if they were normal storage variables.
    tuint256 uint256_var;
    tbytes32 bytes32_var;
    taddress address_var;

    // Can even compose to create a transient mapping.
    mapping(address => tuint256) transient_addr_to_uint;

    function test_defaultValues() public {
        // Default to 0 like storage variables.
        assertEq(uint256_var.get(), 0);
        assertEq(bytes32_var.get(), 0);
        assertEq(address_var.get(), address(0));
    }

    function test_setUint256(uint256 value1, uint256 value2) public {
        // Can set and get values.
        uint256_var.set(value1);
        assertEq(uint256_var.get(), value1);
        uint256_var.set(value2);
        assertEq(uint256_var.get(), value2);
    }

    function test_setBytes32(bytes32 value1, bytes32 value2) public {
        // Can set and get values.
        bytes32_var.set(value1);
        assertEq(bytes32_var.get(), value1);
        bytes32_var.set(value2);
        assertEq(bytes32_var.get(), value2);
    }

    function test_setAddress(address value1, address value2) public {
        // Can set and get values.
        address_var.set(value1);
        assertEq(address_var.get(), value1);
        address_var.set(value2);
        assertEq(address_var.get(), value2);
    }

    function test_setAddrUintMap(address key, uint256 value) public {
        // Mapping works as you'd expect.
        assertEq(transient_addr_to_uint[key].get(), 0);
        transient_addr_to_uint[key].set(value);
        assertEq(transient_addr_to_uint[key].get(), value);
    }
}
```

## [Transient Bytes](./src/TransientBytesLib.sol)

Mimics Solidity `bytes` but instead of being stored in persistent storage uses EIP-1153 transient
storage. (Note while technically defined as a storage struct the underlying library never interacts
with persistent storage and merely uses the `storage` definition to get access to a unique base slot).

Usage (taken from [`TransientBytes.t.sol`](./test/TransientBytes.t.sol)):

```solidity

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {TransientBytes} from "../src/TransientBytesLib.sol";

/// @author philogy <https://github.com/philogy>
contract TransientBytesTest {
    TransientBytes data;

    // Has an unreachable theoretical maximum length of 2^32 bytes.
    uint256 internal constant MAX_LENGTH = type(uint32).max;

    function test_defaultEmpty() public {
        assertEq(data.get(), "");
    }

    function test_setMem(bytes memory inner) public {
        vm.assume(inner.length <= MAX_LENGTH);
        // Store some value.
        data.set(inner);
        // Retrieve the value.
        assertEq(data.get(), inner);
    }

    function test_setCd(bytes calldata inner) public {
        vm.assume(inner.length <= MAX_LENGTH);
        // Store some value directly from calldata (more gas efficient than calling the memory
        // variant with the calldata argument).
        data.setCd(inner);
        // Retrieve data with the same endpoint.
        assertEq(data.get(), inner);
    }
}
```
