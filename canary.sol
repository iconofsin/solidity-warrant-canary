// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

// VIA https://eips.ethereum.org/EIPS/eip-801

interface EIP801 {
    // Triggered when the contract is called for the first time after the canary died.
    event RIP(uint256 block, uint256 time);

    // 
    enum CanaryType
    {
     Unspecified, // THIS IS A CHANGE FROM EIP-801, because Simple must be 1
     Simple,
     SingleFeeder,
     SingleFeederBadFood,
     MultipleFeeders,
     MultipleMandatoryFeeders,
     IOT
    }

    // Determines whether the canary was fed properly to signal e.g. that no warrant was received
    function isAlive() external returns (bool);
    
    // Returns the type of the canary
    function getType() external returns (CanaryType);

    // Returns the block when the canary died. 0 if alive. THIS IS A CHANGE FROM
    // EIP-801, because we can no longer throw in Solidity.
    function getBlockOfDeath() external returns (uint256);
}

/** Never use this directly, it won't work. */
contract BaseCanary is EIP801 {
    uint256 internal _blockOfDeath;
    uint256 internal _timeLastFed;
    uint256 internal _feedingInterval;

    modifier onlyFeeders() virtual { _; }
    
    function _deathRegistered() private view returns (bool) {
        return _blockOfDeath > 0;
    }

    function _kill() private {
        _blockOfDeath = block.number;
        
        emit RIP(_blockOfDeath, block.timestamp);
    }

    function _rip() internal {
        if (!_deathRegistered()) _kill();
    }

    function _feedingSkipped() internal view returns (bool) {
        return _timeLastFed + _feedingInterval < block.timestamp;
    }

    function feed() external onlyFeeders {
        // are you on time to feed the canary?
        if (_feedingSkipped()) {
            // you're too late, perhaps on purpose
            _rip();
        } else {
            _timeLastFed = block.timestamp;
        }
    }
    
    // force kill the canary
    function poison() external onlyFeeders {
        _rip();
    }

    function timeRemaining() external view onlyFeeders returns (uint256) {
        return _feedingInterval - (block.timestamp - _timeLastFed);
    }

    //
    // functions for consumption by anyone
    //
    function isAlive() external override returns (bool) {
        if (_feedingSkipped()) _rip();
      
        return !_deathRegistered();
    }
    
    function getType() external override virtual returns (CanaryType) {
        if (_feedingSkipped()) _rip();
        
        return CanaryType.SingleFeeder;
    }
    
    function getBlockOfDeath() external override returns (uint256) {
        if (_feedingSkipped()) _rip();
        
        return _blockOfDeath;
    }
}

/** SingleFeederCanary can be deployed by an EOA or another contract. 
    The owner is the feeder. */
contract SingleFeederCanary is BaseCanary {
    address private _feeder;
    
    constructor(uint256 feedingIntervalInSeconds) {
        _feeder = msg.sender;
        
        _timeLastFed = block.timestamp;

        _feedingInterval = feedingIntervalInSeconds;
    }

     modifier onlyFeeders override {
        require(msg.sender == _feeder, "You're not the feeder.");

        _;
    }
}

contract MultipleFeedersCanary is BaseCanary {
    mapping(address => uint8) _feeders;

    constructor(address[] memory feeders,
                uint256 feedingIntervalInSeconds) {
        
        for (uint256 f = 0; f < feeders.length; f++) {
            _feeders[feeders[f]] = 1;
        }
        
        _timeLastFed = block.timestamp;

        _feedingInterval = feedingIntervalInSeconds;
    }


     modifier onlyFeeders override {
        require(_feeders[msg.sender] == 1, "You're not a feeder.");

        _;
    }

     function getType() external override returns (CanaryType) {
        if (_feedingSkipped()) _rip();
        
        return CanaryType.MultipleFeeders;
    }
}
