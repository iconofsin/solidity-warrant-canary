// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

import "./SingleFeederCanary.sol";

contract SingleFeederCanaryClientExample is SingleFeederCanary(86400) {
    modifier canaryGuard {
        _autokillGuard();

        require(this.isCanaryAlive(), "RIP. This contract is now unusable.");

        _;
    }

    function performClientAction() external canaryGuard returns (uint256) {
        return block.number;
    }

    function getTimeLastFed() external canaryGuard returns (uint256) {
        return _timeLastFed;
    }

    function getFeedingInterval() external canaryGuard returns (uint256) {
        return _feedingInterval;
    }

    
}
