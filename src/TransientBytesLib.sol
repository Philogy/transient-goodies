// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

struct TransientBytes {
    uint256 __placeholder;
}

using TransientBytesLib for TransientBytes global;

/// @author philogy <https://github.com/philogy>
library TransientBytesLib {
    error DataTooLarge();
    error OutOfOrderSlots();
    error RangeTooLarge();

    /// @dev 4-bytes is way above current max contract size, meant to account for future EVM
    /// versions.
    uint256 internal constant LENGTH_MASK = 0xffffffff;
    uint256 internal constant MAX_LENGTH = LENGTH_MASK;
    uint256 internal constant LENGTH_BYTES = 4;

    function length(TransientBytes storage self) internal view returns (uint256 len) {
        /// @solidity memory-safe-assembly
        assembly {
            let head := tload(self.slot)
            len := shr(sub(256, mul(LENGTH_BYTES, 8)), head)
        }
    }

    function setCd(TransientBytes storage self, bytes calldata data) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let len := data.length

            if gt(len, LENGTH_MASK) {
                mstore(0x00, 0x54ef47ee /* DataTooLarge() */ )
                revert(0x1c, 0x04)
            }

            // Store first word packed with length
            let head := calldataload(sub(data.offset, LENGTH_BYTES))
            tstore(self.slot, head)

            if gt(len, sub(32, LENGTH_BYTES)) {
                // Derive extended slots.
                mstore(0x00, self.slot)
                let slot := keccak256(0x00, 0x20)

                // Store remainder.
                let offset := add(data.offset, sub(0x20, LENGTH_BYTES))
                // Ensure each loop can do cheap comparison to see if it's at the end.
                let endOffset := sub(add(data.offset, len), 1)
                for {} 1 {} {
                    tstore(slot, calldataload(offset))
                    offset := add(offset, 0x20)
                    if gt(offset, endOffset) { break }
                    slot := add(slot, 1)
                }
            }
        }
    }

    function set(TransientBytes storage self, bytes memory data) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let len := mload(data)

            if gt(len, LENGTH_MASK) {
                mstore(0x00, 0x54ef47ee /* DataTooLarge() */ )
                revert(0x1c, 0x04)
            }

            // Store first word packed with length
            let dataStart := add(data, 0x20)
            let head := mload(sub(dataStart, LENGTH_BYTES))
            tstore(self.slot, head)

            if gt(len, sub(0x20, LENGTH_BYTES)) {
                // Derive extended slots.
                mstore(0x00, self.slot)
                let slot := keccak256(0x00, 0x20)

                // Store remainder.
                let offset := add(dataStart, sub(0x20, LENGTH_BYTES))
                // Ensure each loop can do cheap comparison to see if it's at the end.
                let endOffset := sub(add(dataStart, len), 1)
                for {} 1 {} {
                    tstore(slot, mload(offset))
                    offset := add(offset, 0x20)
                    if gt(offset, endOffset) { break }
                    slot := add(slot, 1)
                }
            }
        }
    }

    function get(TransientBytes storage self) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            // Allocate and load head.
            data := mload(0x40)
            mstore(data, 0)
            mstore(add(data, sub(0x20, LENGTH_BYTES)), tload(self.slot))
            // Get length and update free pointer.
            let dataStart := add(data, 0x20)
            let len := mload(data)
            mstore(0x40, add(dataStart, len))

            if gt(len, sub(0x20, LENGTH_BYTES)) {
                // Derive extended slots.
                mstore(0x00, self.slot)
                let slot := keccak256(0x00, 0x20)

                // Store remainder.
                let offset := add(dataStart, sub(0x20, LENGTH_BYTES))
                let endOffset := add(dataStart, len)
                for {} 1 {} {
                    mstore(offset, tload(slot))
                    offset := add(offset, 0x20)
                    if gt(offset, endOffset) { break }
                    slot := add(slot, 1)
                }
                mstore(endOffset, 0)
            }
        }
    }

    function agus(TransientBytes storage self) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Resetting head automatically sets length to 0, rest remains in accessible.
            tstore(self.slot, 0)
        }
    }
}
