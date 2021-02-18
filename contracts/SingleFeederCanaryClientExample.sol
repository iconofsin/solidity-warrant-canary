// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

import "./SingleFeederCanary.sol";

contract SingleFeederCanaryClientExample is SingleFeederCanary(86400) {
    function performClientAction() external canaryGuard returns (uint256 res) {
        return block.number;
    }

    function getTimeLastFed() external canaryGuard returns (uint256 res) {
        return timeLastFed;
    }

    function getFeedingInterval() external canaryGuard returns (uint256 res) {
        return feedingInterval;
    }

    
}
