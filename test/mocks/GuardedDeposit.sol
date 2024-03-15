// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "../../src/ReentrancyGuard.sol";

/// @author philogy <https://github.com/philogy>
contract GuardedDeposit is ReentrancyGuard {
    mapping(address => uint256) public balanceOf;

    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    function withdraw1() external nonReentrant {
        _withdraw();
    }

    function withdraw2() external nonReentrant {
        _withdraw();
    }

    function vulnerableWithdraw() external {
        _withdraw();
    }

    function _withdraw() internal {
        uint256 amount = balanceOf[msg.sender];

        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) _bubbleError();

        balanceOf[msg.sender] = 0;
    }

    function _bubbleError() internal pure {
        assembly ("memory-safe") {
            let m := mload(0x40)
            returndatacopy(m, 0, returndatasize())
            revert(m, returndatasize())
        }
    }
}
