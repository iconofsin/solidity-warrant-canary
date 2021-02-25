// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;


import "./EIP801ModifiedDraft.sol";


/// @notice Implements basic canary logic.
abstract contract BaseCanary is EIP801ModifiedDraft {
    
    constructor(uint256 feedingIntervalInSeconds,
                CanaryType canaryTypeValue) {
        // let's try to keep this under 10 years to avoid overflow issues
        require(feedingIntervalInSeconds < 315360000, "The feeding interval must be under 10 years.");
        // and also, don't shoot yourself in the foot, guys
        require(feedingIntervalInSeconds >= 3600, "The feeding interval must be at least 1 hour.");
        
        feedingInterval = feedingIntervalInSeconds;

        canaryType = canaryTypeValue;
        
        timeLastFed = block.timestamp;

        feedBefore = timeLastFed + feedingInterval;
    }
    
    //
    // -PUBLIC-
    //
    
    /// @inheritdoc EIP801ModifiedDraft
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

    /// @inheritdoc EIP801ModifiedDraft
    function getCanaryType() public view override returns (CanaryType) {
        return canaryType;
    }
    
    /// @inheritdoc EIP801ModifiedDraft
    function getCanaryBlockOfDeath() public view override returns (uint256) {        
        return blockOfDeath;
    }

    /// @inheritdoc EIP801ModifiedDraft
    function touchCanary() public override returns (bool alive) {
        if (feedingSkipped()) {
            pronounceDead();
            
            alive = false;
        } else {
            alive = isCanaryAlive();
        }
    }    
    
    //
    // -INTERNAL-
    //

    // @dev You must call this from feedCanary if the feeding was successful. Only call under onlyOwner modifier.
    function confirmFeeding() internal {
        feedBefore = block.timestamp + feedingInterval;
        
        timeLastFed = block.timestamp;
    }

    /// @notice If the canary is alive, kills it, records the death block, and emits RIP(...)
    /// @dev Do not execute directly. Override if you need to add self-destruct logic in the
    ///      Client Contract.
    function pronounceDead() internal {
        // don't kill the bird twice
        if (!isCanaryAlive()) return;

        blockOfDeath = block.number;

        emit RIPCanary(msg.sender, blockOfDeath, block.timestamp);

        if (fnToExecuteOnDeath != UNINITIALIZED_CALLBACK_FN) {
            fnToExecuteOnDeath();
        }
    }

    /// @notice Override this in inherited classes, depending on the canary type.
    modifier onlyFeeders() virtual {
        require(false, "You must override onlyFeeders.");
        
        _;
    }

    modifier canaryGuard {
        require(isCanaryAlive(), "The canary has died.");
        
        if (feedingSkipped()) {
            pronounceDead();
        } else {
            _;
        }
    }
    
    // The block number when the canary died.
    uint256 internal blockOfDeath;
    
    // The timestamps are updated on every feeding.
    uint256 internal feedBefore;
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
        return feedBefore < block.timestamp;
    }
}
