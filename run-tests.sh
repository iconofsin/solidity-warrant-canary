truffle compile
truffle deploy --compile-none --reset
truffle test test/SingleFeederCanary.t-II.js --compile-none
truffle test test/SingleFeederCanary.t-I.js --compile-none
truffle test test/SingleFeederCanary.t-III.js --compile-none
truffle test test/SingleFeederCanary.t-IV.js --compile-none
truffle test test/SingleFeederCanary.t-V.js --compile-none
