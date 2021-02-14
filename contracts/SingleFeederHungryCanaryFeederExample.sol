// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

import "./SingleFeederCanary.sol";

// this one needs to be fed every 10 seconds
contract SingleFeederHungryCanaryClientExample is SingleFeederCanary(10) {
    modifier canaryGuard {
        _autokillGuard();

        require(this.isCanaryAlive(), "RIP. This contract is now unusable.");

        _;
    }

    function getTimeLastFed() external canaryGuard returns (uint256) {
        return _timeLastFed;
    }
    
    function getFeedingInterval() external canaryGuard returns (uint256) {
        return _feedingInterval;
    }    
}
