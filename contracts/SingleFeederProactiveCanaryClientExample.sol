// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

import "./BaseCanary.sol";

/// @notice Can be deployed by an EOA or another contract.  Only one contract
///         needs to feed this one.
contract SingleFeederProactiveCanaryClientExample is BaseCanary {
    // The owner is the feeder, but with minimal modifications to
    //         the constructor, anyone could be.
    address private _feeder;

    event IAmDead();
    
    function onDeath() internal {
        emit IAmDead();
    }
    
    constructor(uint256 feedingIntervalInSeconds)
        BaseCanary(feedingIntervalInSeconds, CanaryType.SingleFeeder) {
        _feeder = msg.sender;
        feedingInterval = 10;
        setActionToExecuteOnDeath(onDeath);
    }

    /// @inheritdoc BaseCanary
    modifier onlyFeeders override {
        require(msg.sender == _feeder, "You're not the feeder.");
        
        _;
    }

    /// @inheritdoc BaseCanary
    function feedCanary() public override canaryGuard onlyFeeders {
        confirmFeeding();
    }
}
