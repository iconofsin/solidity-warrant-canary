const SingleFeederProactiveCanaryClientExample = artifacts.require("SingleFeederProactiveCanaryClientExample");

module.exports = function(deployer) {
    deployer.deploy(SingleFeederProactiveCanaryClientExample, 3600);
};
