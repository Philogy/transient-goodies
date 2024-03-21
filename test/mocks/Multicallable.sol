// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PayableMulticallable} from "../../src/PayableMulticallable.sol";

/// @author philogy <https://github.com/philogy>
contract Multicallable is PayableMulticallable {
    mapping(address => uint256) public balanceOf;

    function deposit(uint256 amount) external payable standalonePayable {
        balanceOf[msg.sender] += useValue(amount);
    }

    function withdraw(uint256 amount) external payable {
        balanceOf[msg.sender] -= amount;
        (bool suc,) = msg.sender.call{value: amount}("");
        require(suc, "CALL_FAILED");
    }

    function returnRemainder() external payable {
        _returnRemainingValue(msg.sender);
    }
}
