// adjusted from
// https://ethereum.stackexchange.com/questions/48627/how-to-catch-revert-error-in-truffle-test-javascript/48629
const PREFIX = "VM Exception while processing transaction: ";

async function tryCatch(promise, message) {
    let tx
    
    try {
        tx = await promise;
    }
    catch (error) {
        assert(error, "Expected an error but did not get one");
        assert(error.message.startsWith(PREFIX + message), "Expected an error starting with '" + PREFIX + message + "' but got '" + error.message + "' instead");
    }

    return tx;
};

module.exports = {
    catchRevert            : async function(promise) { return await tryCatch(promise, "revert"             );},
    catchOutOfGas          : async function(promise) { return await tryCatch(promise, "out of gas"         );},
    catchInvalidJump       : async function(promise) { return await tryCatch(promise, "invalid JUMP"       );},
    catchInvalidOpcode     : async function(promise) { return await tryCatch(promise, "invalid opcode"     );},
    catchStackOverflow     : async function(promise) { return await tryCatch(promise, "stack overflow"     );},
    catchStackUnderflow    : async function(promise) { return await tryCatch(promise, "stack underflow"    );},
    catchStaticStateChange : async function(promise) { return await tryCatch(promise, "static state change");},
};
