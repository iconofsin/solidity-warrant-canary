const SingleFeederCanaryClientExample = artifacts.require('SingleFeederCanaryClientExample');
const SingleFeederHungryCanaryClientExample = artifacts.require('SingleFeederHungryCanaryClientExample');
const EIP801Draft = artifacts.require('EIP801ModifiedDraft');

const truffleAssert = require('truffle-assertions');

require('chai')
    .use(require('chai-as-promised'))
    .should()

function timeout(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

contract('Touching I', async accounts => {

    let client;

    beforeEach('setup contract for each test case', async () => {
        client = await SingleFeederHungryCanaryClientExample.deployed();
    })
    
    it('6 - touchCanary() is callable by anyone', async () => {
        await truffleAssert.passes(client.touchCanary({from: accounts[7]}));
    })
    
    it('6.1 - Pronounce Dead on touchCanary() if hasnt been fed', async () => {
        await client.feedCanary();

        await timeout(12000);

        const tx = await client.touchCanary({from: accounts[4]});

        truffleAssert.eventEmitted(tx, 'RIPCanary');
    })
})
