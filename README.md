# solidity-warrant-canary

untested alpha-quality code, do not use

Warrant Canary (or, rather, the death of) can be used for various purposes:
* To automatically signal a subpoena receipt by an organization from a government agency
* To automatically signal a person's death
* To automatically signal any type of malicious event against a collective entity
* To automatically trigger execution of other code in any of the above event, which
  makes it a usable Dead Man's Switch

This repository implements the following
* EIP801 interface (Solidity)
* BaseCanary (Solidity)
* SingleFeederCanary (Solidity)
* MultipleFeedersCanary (Solidity)
* MultipleMandatoryFeedersCanary (Solidity)
* Web3js/Node.js-based Canary Watch where monitored canaries can be added at will


NOTE: Checking if a canary is alive might cost gas, but in most scenarios is free.
      For every watched canary, the monitor might be charged at most once iff the
      canary has died and the RIP even has not yet been emitted through other means.
