// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {tuint256} from "./TransientPrimitives.sol";

/// @author philogy <https://github.com/philogy>
abstract contract PayableMulticallable {
    error AmountOverflow();
    error EthTransferFailed();

    uint256 private constant _LOCK_FLAG_BIT = 1;

    /// @dev Lowest bit indicates that the lock is set.
    tuint256 private _topLevelValueAndLock;

    modifier standalonePayable() {
        uint256 valueAndLock = _topLevelValueAndLock.get();
        bool topLevel = valueAndLock & 1 == 0;
        if (topLevel) _topLevelValueAndLock.set(_LOCK_FLAG_BIT | (msg.value << 1));

        _;
        if (topLevel) _topLevelValueAndLock.set(0);
    }

    function multicall(bytes[] calldata data) external payable returns (bytes[] memory) {
        // Taken from Solady's Multicallable (https://github.com/Vectorized/solady/blob/main/src/utils/Multicallable.sol).
        assembly {
            let wasLocked := and(tload(_topLevelValueAndLock.slot), _LOCK_FLAG_BIT)
            if iszero(wasLocked) { tstore(_topLevelValueAndLock.slot, or(_LOCK_FLAG_BIT, shl(1, callvalue()))) }

            mstore(0x00, 0x20)
            mstore(0x20, data.length) // Store `data.length` into `results`.
            // Early return if no data.
            if iszero(data.length) { return(0x00, 0x40) }

            let results := 0x40
            // `shl` 5 is equivalent to multiplying by 0x20.
            let end := shl(5, data.length)
            // Copy the offsets from calldata into memory.
            calldatacopy(0x40, data.offset, end)
            // Offset into `results`.
            let resultsOffset := end
            // Pointer to the end of `results`.
            end := add(results, end)

            for {} 1 {} {
                // The offset of the current bytes in the calldata.
                let o := add(data.offset, mload(results))
                let m := add(resultsOffset, 0x40)
                // Copy the current bytes from calldata to the memory.
                calldatacopy(
                    m,
                    add(o, 0x20), // The offset of the current bytes' bytes.
                    calldataload(o) // The length of the current bytes.
                )
                if iszero(delegatecall(gas(), address(), m, calldataload(o), codesize(), 0x00)) {
                    // Bubble up the revert if the delegatecall reverts.
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
                // Append the current `resultsOffset` into `results`.
                mstore(results, resultsOffset)
                results := add(results, 0x20)
                // Append the `returndatasize()`, and the return data.
                mstore(m, returndatasize())
                returndatacopy(add(m, 0x20), 0x00, returndatasize())
                // Advance the `resultsOffset` by `returndatasize() + 0x20`,
                // rounded up to the next multiple of 32.
                resultsOffset := and(add(add(resultsOffset, returndatasize()), 0x3f), 0xffffffffffffffe0)
                if iszero(lt(results, end)) { break }
            }

            if iszero(wasLocked) { tstore(_topLevelValueAndLock.slot, 0) }

            return(0x00, add(resultsOffset, 0x40))
        }
    }

    function useValue(uint256 amount) internal returns (uint256) {
        uint256 shifted = amount << 1;
        // Will underflow and revert if amount above remaining value. (If lock not acquired amount
        // is zero anyway).
        _topLevelValueAndLock.dec(shifted);
        if (shifted >> 1 != amount) revert AmountOverflow();
        return amount;
    }

    function useAllValue() internal returns (uint256 value) {
        uint256 valueAndLock = _topLevelValueAndLock.get();
        value = valueAndLock >> 1;
        _topLevelValueAndLock.set(valueAndLock & _LOCK_FLAG_BIT);
    }

    function _returnRemainingValue(address to) internal {
        uint256 valueAndLock = _topLevelValueAndLock.get();
        uint256 value = valueAndLock >> 1;
        if (value > 0) {
            (bool suc,) = to.call{value: value}("");
            if (!suc) revert EthTransferFailed();
            // If value was above zero the lock *must've* been acquired, return to base state.
            _topLevelValueAndLock.set(_LOCK_FLAG_BIT);
        }
    }
}
