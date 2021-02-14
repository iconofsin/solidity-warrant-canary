const SingleFeederCanaryClientExample = artifacts.require('SingleFeederCanaryClientExample');
const SingleFeederHungryCanaryClientExample = artifacts.require('SingleFeederHungryCanaryClientExample');
const EIP801Draft = artifacts.require('EIP801Draft');

const truffleAssert = require('truffle-assertions');

require('chai')
    .use(require('chai-as-promised'))
    .should()

function timeout(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}


contract('Feeding II', async accounts => {

    let client;

    beforeEach('setup contract for each test case', async () => {
        client = await SingleFeederHungryCanaryClientExample.deployed();
    })
    
    it('2.2 - Skipped Feeding kills the canary', async () => {
        const blockOfDeath = await client.getCanaryBlockOfDeath.call();

        assert.equal(blockOfDeath.valueOf(), 0);
        
        await client.feedCanary();
        
        let isAlive = await client.isCanaryAlive();
        
        assert.isTrue(isAlive);
        
        await timeout(11000);
        
        await client.feedCanary();

        isAlive = await client.isCanaryAlive();
        
        assert.isFalse(isAlive);
    })
})


contract('Poisoning', async accounts => {
    
    let client;

    beforeEach('setup contract for each test case', async () => {
        client = await SingleFeederCanaryClientExample.deployed();
    })

    // 3. Only the Client Contract owner ({_feeder}) can poison the canary (poisonCanary()).
    // 3.1 When poisoned, the canary is Pronounced Dead.
    it('3 - Only the feeder can poison the canary', async () => {
        const nonFeeder = accounts[1];
        const feeder = accounts[0];
        
        await truffleAssert.reverts(client.poisonCanary({from: nonFeeder}),
                                    "You're not the feeder.");
        
        await truffleAssert.passes(client.poisonCanary({from: feeder}));
        
        const isAlive = await client.isCanaryAlive();

        assert.isFalse(isAlive);
      })
    
    it('3.1 - When poisoned, the canary is Pronounced Dead', async () => {
        const feeder = accounts[0];
        
        await client.poisonCanary({from: feeder});
        
        const isAlive = await client.isCanaryAlive();
        const blockOfDeath = await client.getCanaryBlockOfDeath.call();

        assert.isFalse(isAlive);
        assert.isAbove(blockOfDeath.valueOf().toNumber(), 0);
      })

})
