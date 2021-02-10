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
