[![Coverage Status](https://coveralls.io/repos/github/luisvid/simple-payment-channel/badge.svg)](https://coveralls.io/github/luisvid/simple-payment-channel)

# simple one-way payment channel


## Based on these tutorials: 
- https://medium.com/blockchannel/counterfactual-for-dummies-part-1-8ff164f78540
- https://programtheblockchain.com/posts/2018/02/23/writing-a-simple-payment-channel

About the tests:
- https://truffleframework.com/docs/truffle/testing/writing-tests-in-javascript

## Running the tests

```
$ npm i
$ ganache-cli -m "nose phone clip fee agent crop decorate spell album february oppose anxiety"
$ npm run test
```

## Some issues I found and how I solved them


### Issues with new versión 0.5.0

If you're using ^v5.0.0 (including beta releases), you can bring your own compiler by adding this in your truffle config file (in this example it's set to 0.4.25):

```
module.exports = {
  ...
  compilers: {
    solc: {
      version: "0.4.25",
    },
  },
  ...
};
```

You can query the list of available compiler versions by running this:
``` 
truffle compile --list
```

### Error: Data location must be "storage" or "memory"

```
SimplePaymentChannel.sol:120:49: TypeError: Data location must be "storage" or "memory" for parameter in function, but none was given.
    function isValidSignature(uint256 _balance, bytes _signedMessage)
                                                ^------------------^
```

- https://ethereum.stackexchange.com/questions/63294/typeerror-data-location-must-be-storage-or-memory-for-parameter-in-function


### TypeError: Member "transfer" not found or not visible after argument-dependent lookup in address.

This is due to some breaking changes in Solidity version 0.5. Namely that an address has to be marked as payable - otherwise it won't have the transfer function. More info here: https://solidity.readthedocs.io/en/v0.5.0/050-breaking-changes.html#explicitness-requirements

So just change you function parameters from address _payeeAddr to address payable _payeeAddr and it will work just fine.


### Yet not resolved: Truffle shows no output when running tests

- https:// ethereum.stackexchange.com/questions/66629/truffle-does-nothing-and-shows-no-output-when-running-tests

Important: breaking change for versions >= 0.5.0

### Yet not resolved: solidity-coverage
solidity-coverage requires compilation with solc >= 0.4.21. We're prefixing our own instrumentation events with the emit keyword to reduce warnings volume when running the tool.
