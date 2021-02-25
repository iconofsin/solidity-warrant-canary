// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

import "./BaseCanary.sol";

/// @notice Any one feeder can feed the canary so it keeps on living.
///         There must be at least two.
contract MultipleFeedersCanary is BaseCanary {
    mapping(address => uint8) private _feeders;
    uint8 private constant FEEDER_FLAG = 1;
        
    /// @param feeders Addresses of the feeders who are allowed to feed the canary.
    /// @param feedingIntervalInSeconds How often any one of them must do so?
    constructor(address[] memory feeders,
                uint256 feedingIntervalInSeconds)
        BaseCanary(feedingIntervalInSeconds, CanaryType.MultipleFeeders) {
        
        require(feeders.length > 1, "Need at least 2 feeders.");
        
        for (uint256 f = 0; f < feeders.length; f++) {
            _feeders[feeders[f]] = FEEDER_FLAG;
        }
    }

    /// @inheritdoc BaseCanary
    modifier onlyFeeders override {
        require(_feeders[msg.sender] == FEEDER_FLAG, "You're not a feeder.");
        
        _;
    }

    /// @inheritdoc BaseCanary
    function feedCanary() public override canaryGuard onlyFeeders {
        confirmFeeding();
    }
}
