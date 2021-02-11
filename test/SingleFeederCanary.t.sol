// 1. On deployment, {_feeder}, {_blockOfDeath}, {_timeLastFed}, and {_feedingInterval} are all set to correct values.
//    {_feeder} == msg.sender (Client Contract owner)
//    {_timeLastFed} == block.timestamp (when the contract is deployed)
//    {_blockOfDeath} == 0
//    {_feedingInterval} == feedingIntervalInSeconds, passed as the argument to constructor
// 2. Only the contract owner ({_feeder}) can feed the canary (feedCanary())
// 2.1 Feeding the canary updates {_timeLastFed} to current block.timestamp
// 2.2 If previous feeding was over {_feedingInterval} seconds prior to the current feeding,
//     the canary is automatically Pronounced Dead, the feeding is canceled and no longer
//     possible.
// 3. Only the Client Contract owner ({_feeder}) can poison the canary (poisonCanary()).
// 3.1 When poisoned, the canary is Pronounced Dead.
// 4. getCanaryType returns CanaryType.SingleFeeder
// 5. Pronouncing the canary Dead has the following permanent effects;
//    {_feeder} is set to 0x0, that is, the canary is disowned. This renders all onlyFeeders
//              transactions inaccessible forever. The Client Contract can be maimed in this
//              fashion as well if it uses the onlyFeeders modifier to control access to its
//              regular features.
//    {_blockOfDeath} is set to block.number (at the time when the canary is pronounced dead)
//    {RIPCanary} is emitted with Client Contract address, block and time of death.
// 6. isCanaryAlive and getBlockOfDeath initially return true and 0.
// 6.1 After the canary is Pronounced Dead, isCanaryAlive returns false, getBlockOfDeath returns
//     the block of death (a positive number).
// 6.2 If the canary has died (of hunger), but has not been pronounced dead, isCanaryAlive and getBlockOfDeath return false and 0, which misrepresents the canary's health and is by design: these are free calls, not paid transactions.
// 7. touchCanary is callable by anyone.
// 7.1 If previous feeding was over {_feedingInterval} seconds prior to potential current feeding
//     (i.e. the canary has died of hunger), calling touchCanary causes it to be Pronounced Dead
//     with all the effects described above (5).
// 7.2 In all cases touchCanary returns accurate representation of the canary's health: true if the canary is alive, false otherwise.


