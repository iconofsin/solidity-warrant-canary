// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

/// @title An implementation of the draft interface from EIP-801.
/// @notice Introduces minor changes compared EIP-801 [https://eips.ethereum.org/EIPS/eip-801]
///         Methods have been renamed to avoid potential conflicts with other intefaces
///         and contract methods and to increase clarity.
interface EIP801 {
    /// @notice Triggered when the contract is called for the first time after the canary died.
    ///         NOTE: EIP-801 had no arguments and named this simply RIP.         
    /// @param block The block when the canary died.
    /// @param time The time when the canary died.
    event RIPCanary(uint256 block, uint256 time);

    /// @notice Types of canaries. Per EIP-801. Unfortunately, EIP-801 does not explain
    ///         what either SingleFeederBadFood or IOT do. 
    enum CanaryType
    {
     // THIS IS A CHANGE FROM EIP-801, because Simple must be 1
     Unspecified, 
     Simple,
     SingleFeeder,
     SingleFeederBadFood,
     MultipleFeeders,
     MultipleMandatoryFeeders,
     IOT
    }

    /// @notice Determines whether the canary was fed properly to signal e.g. that no warrant
    ///         was received. EIP-801 name: isAlive.
    function isCanaryAlive() external returns (bool);
    
    /// @notice Returns the type of the canary. EIP-801 name: getType
    function getCanaryType() external returns (CanaryType);

    /// @notice Returns the block when the canary died. 0 if alive. THIS IS A CHANGE FROM
    ///         EIP-801, because we can no longer throw in Solidity. EIP-801 name: getBlockOfDeath.
    function getCanaryBlockOfDeath() external returns (uint256);
}

/// @notice Implements basic canary logic. Never use this directly. 
contract BaseCanary is EIP801 {
    // The block number when the canary died.
    uint256 internal _blockOfDeath;
    // This is updated every time it's fed.
    uint256 internal _timeLastFed;
    // Set in the constructor. Failing to maintain feeding schedule kills the canary.
    uint256 internal _feedingInterval;
    // default to
    CanaryType constant private _canaryType = CanaryType.Simple;

    /// @notice Override this in inherited classes, depending on the canary type.
    modifier onlyFeeders() virtual { _; }

    /// @notice Checks if the canary's time of death has been called by recording
    ///         the block when it died.  The default, block 0, means the canary
    ///         is considered alive. "Death registered" always implies RIP has
    ///         been emitted.
    /// @return True if the canary is alive, false otherwise.
    function _deathRegistered() internal view returns (bool) {
        return _blockOfDeath > 0;
    }

    /// @notice If the canary is alive, kills it, records the death block, and emits RIP(...)
    function _rip() internal {
        // don't kill the bird twice
        if (_deathRegistered()) return;

        _blockOfDeath = block.number;

        emit RIPCanary(_blockOfDeath, block.timestamp);
    }

    /// @notice Determines if the canary must die of hunger right now.
    /// @return True if it's as good as dead, false otherwise.
    function _feedingSkipped() internal view returns (bool) {
        return _timeLastFed + _feedingInterval < block.timestamp;
    }

    /// @notice Kills the canary if it's alive, but the canary wasn't fed on schedule
    function _autokillGuard() internal {
        if (!_deathRegistered() && _feedingSkipped()) {
            _rip();
        }
    }
    
     /// @notice Determines the time remaining before the canary dies
    ///         from hunger.
    /// @return A positive number of seconds if there's still time to feed
    ///         the canary, a negative number otherwise.
    function timeRemaining() external view onlyFeeders returns (uint256) {
        return _feedingInterval - (block.timestamp - _timeLastFed);
    }

    /// @notice Feeds the canary. This must only be accessible to feeder(s).
    /// @dev Override and implement in a derived class.
    function feed() external virtual onlyFeeders {}
    
    
    /// @notice Instantly kills the canary if alive.
    ///         Note that any one feeder can poison the canary for all types.
    ///         Override this method if you need a different behaviour.
    function poison() external virtual onlyFeeders {
        _rip();
    }

   
    //
    // functions for consumption by anyone
    //
    /// @inheritdoc EIP801
    function isCanaryAlive() external override returns (bool) {
        _autokillGuard();
        
        return !_deathRegistered();
    }

    /// @inheritdoc EIP801
    function getCanaryType() external override returns (CanaryType) {
        _autokillGuard();
                
        return _canaryType;
    }
    

    /// @inheritdoc EIP801
    function getCanaryBlockOfDeath() external override returns (uint256) {
        _autokillGuard();
        
        return _blockOfDeath;
    }
}

/// @notice Can be deployed by an EOA or another contract.  Only one contract
///         needs to feed this one.
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
    function feed() external override onlyFeeders {
        _autokillGuard();

        if (!_deathRegistered()) {
            _timeLastFed = block.timestamp;
        }
    }
}

/// @notice Any one feeder can feed the canary so it keeps on living.
///         There must be at least two.
contract MultipleFeedersCanary is BaseCanary {
    mapping(address => uint8) _feeders;
    //
    CanaryType constant private _canaryType = CanaryType.MultipleFeeders;

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
    function feed() external override onlyFeeders {
        _autokillGuard();

        if (!_deathRegistered()) {
            _timeLastFed = block.timestamp;
        }
    }
}

/// @notice Every feeder must feed the canary so it doesn't die.
///         There must be at least two. 
contract MultipleMandatoryFeedersCanary is BaseCanary {
    address[] _feeders;
    mapping(address => uint256) _feedingLog;
    //
    CanaryType constant private _canaryType = CanaryType.MultipleMandatoryFeeders;


    constructor(address[] memory feeders,
                uint256 feedingIntervalInSeconds) {
        require(feeders.length > 1, "Need at least two feeders.");
        
        _feeders = new address[](feeders.length);
        
        _timeLastFed = block.timestamp;

        for (uint256 f = 0; f < feeders.length; f++) {
            _feedingLog[feeders[f]] = _timeLastFed;
            _feeders.push(feeders[f]);
        }

        _feedingInterval = feedingIntervalInSeconds;
    }

    /// @inheritdoc BaseCanary
    modifier onlyFeeders override {
        require(_feedingLog[msg.sender] > 0, "You're not a feeder.");
        
        _;
    }

    /// @inheritdoc BaseCanary
    function feed() external override onlyFeeders {
        _autokillGuard();

        if (!_deathRegistered()) {
             // okay, YOU have fed the canary...
            _feedingLog[msg.sender] = block.timestamp;

            // ...but how about your feeder pals?
            bool everyoneHasFedTheCanary = true;
            
            for (uint256 f = 0; f < _feeders.length; f++) {
                everyoneHasFedTheCanary =
                    everyoneHasFedTheCanary &&
                    (_timeLastFed + _feedingInterval
                     <=
                     _feedingLog[_feeders[f]]);
            }

            if (everyoneHasFedTheCanary)
                _timeLastFed = block.timestamp;
        }
    }

   
}
