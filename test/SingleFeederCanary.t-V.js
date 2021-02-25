const SingleFeederProactiveCanaryClientExample = artifacts.require('SingleFeederProactiveCanaryClientExample');
const EIP801Draft = artifacts.require('EIP801ModifiedDraft');

const truffleAssert = require('truffle-assertions');

require('chai')
    .use(require('chai-as-promised'))
    .should()

function timeout(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

contract('Poisoned and Aware', async accounts => {

    let client;

    beforeEach('setup contract for each test case', async () => {
        client = await SingleFeederProactiveCanaryClientExample.deployed();
    })
    
    it(' - poisonCanary() performs the custom action and emits IAmDead()', async () => {
        const tx = await client.poisonCanary();
        //console.log(tx);

        truffleAssert.eventEmitted(tx, 'RIPCanary');
        truffleAssert.eventEmitted(tx, 'IAmDead');
    })    
})
