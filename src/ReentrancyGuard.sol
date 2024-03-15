// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {tuint256} from "./TransientPrimitives.sol";

/// @author philogy <https://github.com/philogy>
abstract contract ReentrancyGuard {
    tuint256 private _lockState;

    uint256 internal constant DEFAULT_UNLOCKED = 0;
    uint256 internal constant LOCKED = 1;

    error Reentering();

    modifier nonReentrant() {
        if (_lockState.get() != DEFAULT_UNLOCKED) revert Reentering();
        _lockState.set(LOCKED);
        _;
        _lockState.set(DEFAULT_UNLOCKED);
    }
}
