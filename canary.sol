// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

/// @title An implementation of the draft interface from EIP-801.
/// @notice Introduces minor changes compared EIP-801 [https://eips.ethereum.org/EIPS/eip-801]
interface EIP801 {
    /// @notice Triggered when the contract is called for the first time after the canary died.
    ///         NOTE: EIP-801 had no arguments.         
    /// @param block The block when the canary died.
    /// @param time The time when the canary died.
    event RIP(uint256 block, uint256 time);

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
    ///         was received.
    function isAlive() external returns (bool);
    
    /// @notice Returns the type of the canary
    function getType() external returns (CanaryType);

    /// @notice Returns the block when the canary died. 0 if alive. THIS IS A CHANGE FROM
    ///         EIP-801, because we can no longer throw in Solidity.
    function getBlockOfDeath() external returns (uint256);
}

/// @notice Implements basic canary logic. Never use this directly. 
contract BaseCanary is EIP801 {
    // The block number when the canary died.
    uint256 internal _blockOfDeath;
    // This is updated every time it's fed.
    uint256 internal _timeLastFed;
    // Set in the constructor. Failing to maintain feeding schedule kills the canary.
    uint256 internal _feedingInterval;

    /// @notice Override this in inherited classes, depending on the canary type.
    modifier onlyFeeders() virtual { _; }

    /// @notice Checks if the canary's time of death has been called by recording
    ///         the block when it died.  The default, block 0, means the canary
    ///         is considered alive.
    /// @return True if the canary is alive, false otherwise.
    function _deathRegistered() private view returns (bool) {
        return _blockOfDeath > 0;
    }

    /// @notice Marks the canary as dead, records the death block and emits RIP(...)
    function _kill() private {
        _blockOfDeath = block.number;
        
        emit RIP(_blockOfDeath, block.timestamp);
    }

    /// @notice Wrapper around _kill that prevents anyone from killing a canary
    ///         that's already dead.
    function _rip() internal {
        if (!_deathRegistered()) _kill();
    }

    /// @notice Determines if the canary must die of hunger right now.
    /// @return True if it's as good as dead, false otherwise.
    function _feedingSkipped() internal view returns (bool) {
        return _timeLastFed + _feedingInterval < block.timestamp;
    }

    /// @notice Feeds the canary. This must only be accessible to feeder(s).
    /// @dev Override and implement in a derived class.
    function feed() external virtual onlyFeeders {}
    
    
    /// @notice Instantly kills the canary if alive.
    function poison() external onlyFeeders {
        _rip();
    }

    /// @notice Determines the time remaining before the canary dies
    ///         from hunger.
    /// @return A positive number of seconds if there's still time to feed
    ///         the canary, a negative number otherwise.
    function timeRemaining() external view onlyFeeders returns (uint256) {
        return _feedingInterval - (block.timestamp - _timeLastFed);
    }

    //
    // functions for consumption by anyone
    //
    /// @inheritdoc EIP801
    function isAlive() external override returns (bool) {
        if (_feedingSkipped()) _rip();
      
        return !_deathRegistered();
    }

    /// @inheritdoc EIP801
    function getType() external override virtual returns (CanaryType) {}

    /// @inheritdoc EIP801
    function getBlockOfDeath() external override returns (uint256) {
        if (_feedingSkipped()) _rip();
        
        return _blockOfDeath;
    }
}

/// @notice Can be deployed by an EOA or another contract.  Only one contract
///         needs to feed this one.
contract SingleFeederCanary is BaseCanary {
    /// @notice The owner is the feeder, but with minimal modifications to
    ///         the constructor, anyone could be.
    address private _feeder;
    
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
    function feed() external override onlyFeeders  {
        // are you on time to feed the canary?
        if (_feedingSkipped()) {
            // you're too late, perhaps on purpose
            _rip();
        } else {
            _timeLastFed = block.timestamp;
        }
    }

    /// @inheritdoc EIP801
    function getType() external override returns (CanaryType) {
        if (_feedingSkipped()) _rip();
        
        return CanaryType.SingleFeeder;
    }
}

/// @notice Any one feeder can feed the canary so it keeps on living.
///         There must be at least two.
contract MultipleFeedersCanary is BaseCanary {
    mapping(address => uint8) _feeders;

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

    /// @inheritdoc EIP801
     function getType() external override returns (CanaryType) {
        if (_feedingSkipped()) _rip();
        
        return CanaryType.MultipleFeeders;
    }
}

/// @notice Every feeder must feed the canary so it doesn't die.
///         There must be at least two. 
contract MultipleMandatoryFeedersCanary is BaseCanary {
    address[] _feeders;
    mapping(address => uint256) _feedingLog;

    constructor(address[] memory feeders,
                uint256 feedingIntervalInSeconds) {
        require(feeders.length > 1, "Need at least two feeders.")
        
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
        // are you on time to feed the canary?
        if (_feedingSkipped()) {
            // you're too late, perhaps on purpose
            _rip();
        } else {
            // okay, YOU have fed the canary...
            _feedingLog[msg.sender] = block.timestamp;

            // ...but how about your pals?
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

    /// @inheritdoc EIP801
    function getType() external override returns (CanaryType) {
        if (_feedingSkipped()) _rip();
        
        return CanaryType.MultipleMandatoryFeeders;
    }
    
}
