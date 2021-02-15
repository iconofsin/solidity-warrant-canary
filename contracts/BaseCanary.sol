// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;


import "./EIP801Draft.sol";


/// @notice Implements basic canary logic.
abstract contract BaseCanary is EIP801Draft {
    
    constructor(uint256 feedingIntervalInSeconds,
                CanaryType canaryTypeValue) {
        
        feedingInterval = feedingIntervalInSeconds;

        canaryType = canaryTypeValue;
        
        timeLastFed = block.timestamp;
    }
    
    //
    // -EXTERNAL-
    //

    

    //
    // -PUBLIC-
    //
    
    /// @inheritdoc EIP801Draft
    function isCanaryAlive() public view override returns (bool) {
        return (blockOfDeath == 0);
    }

    /// @notice Feeds the canary. This must only be accessible to feeder(s).
    /// @dev Override and implement in a derived class.
    function feedCanary() public virtual onlyFeeders {}
    
    
    /// @notice Instantly kills the canary if alive.
    ///         Note that any one feeder can poison the canary for all types.
    ///         Override this method if you need a different behaviour.
    function poisonCanary() public virtual onlyFeeders {
        pronounceDead();
    }

    /// @inheritdoc EIP801Draft
    function getCanaryType() public view override returns (CanaryType) {
        return canaryType;
    }
    
    /// @inheritdoc EIP801Draft
    function getCanaryBlockOfDeath() public view override returns (uint256) {        
        return blockOfDeath;
    }

    /// @inheritdoc EIP801Draft
    function touchCanary() public override returns (bool) {
        killCanaryIfFeedingSkipped();
        
        return isCanaryAlive();
    }    
    
    //
    // -INTERNAL-
    //
     /// @notice If the canary is alive, kills it, records the death block, and emits RIP(...)
    /// @dev Do not execute directly. Override if you need to add self-destruct logic in the
    ///      Client Contract.
    function pronounceDead() internal {
        // don't kill the bird twice
        if (!isCanaryAlive()) return;

        blockOfDeath = block.number;

        if (fnToExecuteOnDeath != UNINITIALIZED_CALLBACK_FN) {
            fnToExecuteOnDeath();
        }

        emit RIPCanary(address(this), blockOfDeath, block.timestamp);
    }

    /// @notice Kills the canary if it's "alive", but wasn't fed on schedule
    function killCanaryIfFeedingSkipped() internal {
        if (feedingSkipped() && isCanaryAlive()) {
            pronounceDead();
        }
    }


    /// @notice Override this in inherited classes, depending on the canary type.
    modifier onlyFeeders() virtual {
        require(false, "You must override onlyFeeders.");
        
        _;
    }

    modifier canaryGuard {
        killCanaryIfFeedingSkipped();

        require(isCanaryAlive(), "The canary has died.");
        
        _;
    }
    
    // The block number when the canary died.
    uint256 internal blockOfDeath;
    
    // The timestamp is updated on every feeding.
    uint256 internal timeLastFed;

    // Set in the constructor. Failing to maintain feeding schedule kills the canary.
    uint256 internal feedingInterval;

    // the default; derived contracts are expected to set their own types
    CanaryType internal canaryType = CanaryType.Simple;

    // pronounceDead calls this if initialized through setActionToExecuteOnDeath
    function() internal fnToExecuteOnDeath;

    // used to check whether fnToExecuteOnDeath is initialized
    function() internal UNINITIALIZED_CALLBACK_FN;

    // execute a callback to the client contract when the canary is pronounced dead
    function setActionToExecuteOnDeath(function() internal callback)
        onlyFeeders
        internal {
        fnToExecuteOnDeath = callback;
    }

   
    //
    // -PRIVATE-
    //
    
    /// @notice Determines if the canary must die of hunger right now.
    /// @return True if it's as good as dead, false otherwise.
    function feedingSkipped() private view returns (bool) {
        return timeLastFed + feedingInterval < block.timestamp;
    }
}
