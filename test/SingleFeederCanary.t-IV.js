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

contract('Touching II', async accounts => {

    let client;

    beforeEach('setup contract for each test case', async () => {
        client = await SingleFeederHungryCanaryClientExample.deployed();
    })
    
    it('6.2 - touchCanary() returns true if alive, false otherwise', async () => {
        await client.feedCanary();

        const touchTrue = await client.touchCanary.call();

        assert.isTrue(touchTrue);

        await timeout(12000);

        const tx = await client.touchCanary({from: accounts[4]});

        truffleAssert.eventEmitted(tx, 'RIPCanary');

        const touchFalse = await client.touchCanary.call();
        
        assert.isFalse(touchFalse);
    })


    it('7 - RIPCanary is only emitted the first time', async () => {
        const tx = await client.touchCanary({from: accounts[4]});
        
        truffleAssert.eventNotEmitted(tx, 'RIPCanary');
    })

    it('5.1 - After the canary is Pronounced Dead, isCanaryAlive() returns false',
       async () => {
           const isAlive = await client.isCanaryAlive.call();

           assert.isFalse(isAlive);
       })

    it('5.2 - After the canary is Pronounced Dead, getBlockOfDeath() is > 0',
       async () => {
           const blockOfDeath = await client.getCanaryBlockOfDeath.call();

           assert.isAbove(blockOfDeath.toNumber(), 0);
       })
    
})
