// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

import "./EIP801Draft.sol";

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