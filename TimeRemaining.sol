    

    /// @notice Determines the time remaining before the canary dies
    ///         from hunger.
    /// @return A positive number of seconds if there's still time to feed
    ///         the canary, a negative number otherwise.
    function timeRemaining() external view onlyFeeders returns (int256) {
        return int256(timeLastFed + feedingInterval - block.timestamp);
    }
