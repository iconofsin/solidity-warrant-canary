// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

import "./SingleFeederCanary.sol";

// this one needs to be fed every 10 seconds
contract SingleFeederHungryCanaryClientExample is SingleFeederCanary(10) {
    function getTimeLastFed() external canaryGuard returns (uint256 res) {
        return timeLastFed;
    }
    
    function getFeedingInterval() external canaryGuard returns (uint256 res) {
        return feedingInterval;
    }    
}
