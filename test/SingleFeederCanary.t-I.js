const SingleFeederCanaryClientExample = artifacts.require('SingleFeederCanaryClientExample');
const SingleFeederHungryCanaryClientExample = artifacts.require('SingleFeederHungryCanaryClientExample');
const EIP801Draft = artifacts.require('EIP801ModifiedDraft');

const truffleAssert = require('truffle-assertions');
const exceptions = require('./exceptions.js')


require('chai')
    .use(require('chai-as-promised'))
    .should()

function timeout(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}


contract('Client Basics', async accounts => {

    let client;

    beforeEach('setup contract for each test case', async () => {
        client = await SingleFeederCanaryClientExample.deployed();
    })


    it('1.1 - Contract feeder should be set to owner', async () => {
        // _feeder is private in BaseCanary, so we test for this by
        // testing modifiers instead (during feeding, etc)
    })

    it('1.2 - Time last fed is set to block.timestamp', async () => {
        const timeLastFed = await client.getTimeLastFed.call();

        //await timeout(2000);
        
        const block = await web3.eth.getBlock("latest");

        assert.isAtLeast(block.timestamp - timeLastFed.toNumber(), 0);
    })

    it('1.3 - Should have zero initial Block of Death', async () => {
        const initialBlockOfDeath = await client.getCanaryBlockOfDeath.call();
        
        assert.equal(initialBlockOfDeath.toNumber(), 0);
    })

    it('1.4 - Feeding interval must be 86400 seconds', async () => {
        const feedingInterval = await client.getFeedingInterval.call();
        
        assert.equal(feedingInterval.toNumber(), 86400);
    })
    
    it('1.5 - The canary is initially alive', async () => {
        const isAlive = await client.isCanaryAlive.call();

        assert.isTrue(isAlive.valueOf());
    })

    it('1.6 - Should be of type SingleFeeder', async () => {
        const canaryType = await client.getCanaryType.call();
        const EXPECTED_CANARY_TYPE = EIP801Draft.CanaryType.SingleFeeder;

        assert.equal(canaryType.valueOf().toNumber(), EXPECTED_CANARY_TYPE);
    })

})

contract('Feeding I', async accounts => {

    let client1;

    beforeEach('setup contract for each test case', async () => {
        client1 = await SingleFeederHungryCanaryClientExample.deployed();
    })
    
    // 2. Only the contract owner ({_feeder}) can feed the canary (feedCanary())
    // 2.1 Feeding the canary updates {_timeLastFed} to current block.timestamp
    // 2.2 If previous feeding was over {_feedingInterval} seconds prior to the current feeding,
    //     the canary is automatically Pronounced Dead, the feeding is canceled and no longer
    //     possible.
    it('2.0 - Feeding interval must be 10 seconds', async () => {
        const feedingInterval = await client1.getFeedingInterval.call();

        assert.equal(feedingInterval.toNumber(), 10);
    })

    it('2.x - Only the feeder can feed the canary', async () => {
        const nonFeeder = accounts[1];
        const feeder = accounts[0];

        await truffleAssert.reverts(client1.feedCanary({from: nonFeeder}),
                                    "You're not the feeder.");

        await truffleAssert.passes(client1.feedCanary({from: feeder}));
    })


    it('2.1 - Feeding updates Time Last Fed', async () => {
        const feedingTimestamp1 = await client1.getTimeLastFed.call();

        await timeout(5000);

        await client1.feedCanary();

        const feedingTimestamp2 = await client1.getTimeLastFed.call();

        assert.isAbove(feedingTimestamp2.toNumber() -
                       feedingTimestamp1.toNumber(), 0);
    })


    // 
    it('2.2a - Guard emits RIPCanary and short-circuits execution forever', async () => {
        await client1.feedCanary();

        await timeout(12000);

        const tx = await client1.feedCanary();

        truffleAssert.eventEmitted(tx, 'RIPCanary');

        await truffleAssert.reverts(
            client1.feedCanary(),
         "The canary has died.");

        
    })

})

                       
