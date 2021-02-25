**An implementation of Warrant Canary for Ethereum.**

Conceptual prerequisites:
- https://en.wikipedia.org/wiki/Warrant_canary
- https://eips.ethereum.org/EIPS/eip-801

**somewhat tested code, do not use just yet**

Warrant Canary (or, rather, the death of) can be used for various purposes:
* To automatically signal a subpoena receipt by an organization from a government agency
* To automatically signal a person's death
* To automatically signal any type of malicious event against a collective entity
* To automatically trigger execution of other code in any of the above events, which
  makes it a usable Dead Man's Switch

This best-effort implementation is inspired by EIP-801, which seems to have been
abandoned, so there are notable implementation discrepancies and even the interface
has changed.

Notes on usage:
- Once a canary is dead, it cannot, should not, must not be revived. The reason for this:
  if you leave a backdoor and revive a canary, you're sending an ambiguous signal to your
  audience. There's no way to guarantee you have performed the revival voluntarily.

- Canaries in this repository are an all-or-nothing proposition, they're either dead
  or alive. If you need to signal varying levels of danger, use a different mechanism or
  a different implementation. For instance, you could implement a ResilientCanary that
  signals levels of hunger, depending on how many feedings the feeder(s) has (have) skipped.

- Derive your client contract from either SingleFeederCanary, MultipleFeedersCanary, or
  MultipleMandatoryFeedersCanary. Use guard modifiers to comply with the interface.
  (See examples/ for implementations used in testing.) Derive other contracts as required
  (OpenZeppelin, etc); SWC is expected to be used in conjunction with other client code.


This repository currently includes the following:
* The modified EIP801 interface (Solidity)
* BaseCanary abstract class (Solidity)
* SingleFeederCanary (Solidity)
* MultipleFeedersCanary (Solidity)
* MultipleMandatoryFeedersCanary (Solidity)
* Test Suite for SingleFeederCanary (truffle/truffle-assert/JavaScript)

## CONCEPTS
A canary is a signaling mechanism. In a perfect world, verifying its state of health would be unambiguous and free. In reality, however, Ethereum, because of the EVM isolation, requires external input and oftentimes gas fees to retrieve any kind of information.

Consequently, the implementations offered here include functions that could misrepresent the canary's state of health gas-free as well as functions that are guaranteed to report it accurately at an expense.

Examine the basic scenario of a canary that needs to be fed every day, or once every 86400 seconds, to be considered alive. Solidity has no timers or scheduled events, so it isn't possible to check automatically.

If a feeding is skipped, the canary is reported as alive if gas-free pure/view functions are used (`isCanaryAlive()`, `getCanaryBlockOfDeath()`). Formally, however, the canary is dead.

In this scenario, whoever calls `touchCanary()` or any other function guarded with the `canaryGuard` modifier first will incur gas fees, but will also cause the canary to be Pronounced Dead.

*Pronouncing Dead*. RIPCanary is emitted, block of death is set, and from this point forward `isCanaryAlive()` *always* returns `false`.

Trying to feed a canary pronounced dead does not change its state. The rationale for this is 1) the nature of a warrant canary says it must be so; 2) it's impossible to verify whether the danger has passed or the feeder is being forced against their will.

Beyond the point of death, all functions guarded with `canaryGuard` will revert with a message ("The canary has died.")

Contracts implementing canary interfaces must therefore be prepared to become unusable when the canary dies for whatever reason.

A standard approach is to
1) Use guard modifiers for every contract functions that implements the contract's business logic. Guards check whether feeding was skipped and pronounce the canary dead if it was. This results in the contract becoming unusable if the canary dies.
2) Make provisions in the contract code for the event of the canary dying. You might want, for example, to transfer assets to a different account that hasn't been compromised or... do nothing if that's acceptable in terms of future interactions of the contract's owner and their audience. In a more complicated scenario, another contract could be called.

To perform a custom action when the canary dies, set it by calling `setActionToExecuteOnDeath` after the contract is deployed. This function takes as its only argument a function that is to be executed when the canary is pronounced dead (right before `RIPCanary` is emitted.)

## TYPES OF CANARIES
_Single Feeder_ - one account must feed the canary.

_Multiple Feeders_ - multiple accounts are allowed to feed the canary, but it's enough if any one of them does.

_Multiple Mandatory Feeders_ - multiple accounts must all feed the canary.

## Donations 
If you find this implementation of Warrant Canary useful, consider donating Ξ to 0xB8E6F89556c3Dc4d38C2251500F9e314039034D3.