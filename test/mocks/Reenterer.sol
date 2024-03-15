// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {GuardedDeposit} from "./GuardedDeposit.sol";

/// @author philogy <https://github.com/philogy>
contract Reenterer {
    GuardedDeposit internal immutable victim;

    bytes4 private targetSelector;
    uint8 private loops;

    constructor(address target) {
        victim = GuardedDeposit(target);
    }

    receive() external payable {
        if (--loops == 0) return;
        (bool success,) = address(victim).call(abi.encodePacked(targetSelector));
        if (!success) _bubbleError();
    }

    function deposit() external payable {
        victim.deposit{value: msg.value}();
    }

    function attack(bytes4 entry, bytes4 reentry, uint8 total) external {
        targetSelector = reentry;
        loops = total;

        (bool success,) = address(victim).call(abi.encodePacked(entry));
        if (!success) _bubbleError();
    }

    function _bubbleError() internal pure {
        assembly ("memory-safe") {
            let m := mload(0x40)
            returndatacopy(m, 0, returndatasize())
            revert(m, returndatasize())
        }
    }
}
