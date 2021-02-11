// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

import "./BaseCanary.sol";

/// @notice Can be deployed by an EOA or another contract.  Only one contract
///         needs to feed this one.
/// @dev EIP801 suggests _autokillGuard() (see implementation of feedCanary())
///      must be called in all contract's functions to guarantee that RIPCanary
///      is emitted (once) as soon as the canary dies. Because of the way Solidity
///      differentiates potentially state-changing transactions and state-changing
///      transactions (it doesn't), this requirement could quickly become costly
///      in terms of gas spendings.
contract SingleFeederCanary is BaseCanary {
    // The owner is the feeder, but with minimal modifications to
    //         the constructor, anyone could be.
    address private _feeder;
    //
    CanaryType constant private _canaryType = CanaryType.SingleFeeder;
    
    constructor(uint256 feedingIntervalInSeconds) {
        _feeder = msg.sender;
        
        _timeLastFed = block.timestamp;

        _feedingInterval = feedingIntervalInSeconds;
    }

    /// @inheritdoc BaseCanary
    modifier onlyFeeders override {
        require(msg.sender == _feeder, "You're not the feeder.");
        
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
