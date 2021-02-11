// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

import "./BaseCanary.sol";

/// @notice Any one feeder can feed the canary so it keeps on living.
///         There must be at least two.
/// @dev EIP801 suggests _autokillGuard() (see implementation of feedCanary())
///      must be called in all contract's functions to guarantee that RIPCanary
///      is emitted (once) as soon as the canary dies. Because of the way Solidity
///      differentiates potentially state-changing transactions and state-changing
///      transactions (it doesn't), this requirement could quickly become costly
///      in terms of gas spendings.
contract MultipleFeedersCanary is BaseCanary {
    mapping(address => uint8) _feeders;
    
    //
    CanaryType constant private _canaryType = CanaryType.MultipleFeeders;

    /// @param feeders Addresses of the feeders who are allowed to feed the canary.
    /// @param feedingIntervalInSeconds How often any one of them must do so?
    constructor(address[] memory feeders,
                uint256 feedingIntervalInSeconds) {
        require(feeders.length > 1, "Need at least 2 feeders.");
        
        for (uint256 f = 0; f < feeders.length; f++) {
            _feeders[feeders[f]] = 1;
        }
        
        _timeLastFed = block.timestamp;

        _feedingInterval = feedingIntervalInSeconds;
    }

    /// @inheritdoc BaseCanary
    modifier onlyFeeders override {
        require(_feeders[msg.sender] == 1, "You're not a feeder.");
        
        _;
    }

    /// @inheritdoc BaseCanary
    function feedCanary() external override onlyFeeders {
        _autokillGuard();

        if (!_deathRegistered()) {
            _timeLastFed = block.timestamp;
        }
    }
}
