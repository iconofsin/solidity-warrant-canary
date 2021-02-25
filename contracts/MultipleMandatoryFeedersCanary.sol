// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

import "./BaseCanary.sol";

/// @notice Every feeder must feed the canary so it doesn't die.
///         There must be at least two.
contract MultipleMandatoryFeedersCanary is BaseCanary {
    address[] private _feeders;

    // timestamp every feeding by any feeder
    mapping(address => uint256) _feedingLog;

    /// @param feeders Addresses of the feeders who all must feed the canary.
    /// @param feedingIntervalInSeconds How often they must do so?
    constructor(address[] memory feeders,
                uint256 feedingIntervalInSeconds)
        BaseCanary(feedingIntervalInSeconds, CanaryType.MultipleMandatoryFeeders) {
        
        require(feeders.length > 1, "Need at least two feeders.");
        
        _feeders = new address[](feeders.length);
        
        for (uint256 f = 0; f < feeders.length; f++) {
            _feedingLog[feeders[f]] = timeLastFed;
            
            _feeders.push(feeders[f]);
        }
    }

    /// @inheritdoc BaseCanary
    modifier onlyFeeders override {
        require(_feedingLog[msg.sender] > 0, "You're not a feeder.");
        
        _;
    }

    /// @inheritdoc BaseCanary
    function feedCanary() public override canaryGuard onlyFeeders {
        // okay, YOU have fed the canary...
        _feedingLog[msg.sender] = block.timestamp;

        // ...but how about your feeder pals?
        bool everyoneHasFedTheCanary = true;
        
        for (uint256 f = 0; f < _feeders.length; f++) {
            everyoneHasFedTheCanary =
                everyoneHasFedTheCanary &&
                (timeLastFed + feedingInterval
                 <=
                 _feedingLog[_feeders[f]]);
        }
        
        if (everyoneHasFedTheCanary)
            confirmFeeding();
    }
}
