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
    ///         was received. EIP-801 name: isAlive. Note that this could misrepresent
    ///         the canary's health. touchCanary to be sure.
    function isCanaryAlive() external view returns (bool);
    
    /// @notice Returns the type of the canary. EIP-801 name: getType
    function getCanaryType() external pure returns (CanaryType);

    /// @notice Returns the block when the canary died. 0 otherwise. THIS IS A CHANGE FROM
    ///         EIP-801, because we can no longer throw in Solidity. EIP-801 name: getBlockOfDeath.
    ///         Note that this could misrepresent the canary's health.  touchCanary to be sure.
    function getCanaryBlockOfDeath() external view returns (uint256);


    // The following function can be used to track the canary without paying any gas.
    // It will not automatically pronounce the canary dead, for instance, if it hasn't been fed
    // on time. As such, it's not a reliable indicator.

    /// @notice Returns true if canary is alive, false otherwise. Unlike isCanaryAlive,
    ///         getCanaryType, and getCanaryBlockOfDeath, guards against misrepresenting
    ///         the canary's health by verifying that it has been both fed and not
    ///         intentionally poisoned. Consequently, touchCanary is a _transaction_, while
    ///         the above are _calls_. 
    function touchCanary() external returns (bool);
}

