const SingleFeederCanary = artifacts.require("SingleFeederCanary");

module.exports = function(deployer) {
  deployer.deploy(SingleFeederCanary, 60*60);
};