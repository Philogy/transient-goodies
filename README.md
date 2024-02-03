# Transient Goodies

As of 0.8.24 [solc](https://github.com/ethereum/solidity) does not grant access to a `storage`-type
specifier to be able to easily define transient storage data structures. This library is meant to be a
collection of various transient storage helpers and data structures.

## [Transient Bytes](./src/TransientBytesLib.sol)

Mimics Solidity `bytes` but instead of being stored in persistent storage uses EIP-1153 transient
storage. (Note while technically defined as a storage struct the underlying library never interacts
with persistent storage and merely uses the `storage` definition to get access to a unique base slot).

Usage (taken from [`TransientBytes.t.sol`](./test/TransientBytes.t.sol)).

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
