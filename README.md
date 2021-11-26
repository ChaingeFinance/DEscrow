# DEscrow

### Features

The seller creates a deal smart contract through the factory contract, and pledges the agreed number of tokens to the deal smart contract. After the buyer and the seller agree to complete the deal or cancel the deal, the pledged token will be returned to the accounts of both parties, otherwise the token will always be stored in the smart contract.


## Factory contract API

> Used to create a Deal contract

### Create Deal interface

_personA Is the seller account address.

_personB Is the buyer's account address.

_dealToken Is the contract address of the transaction token, if the transaction is not a token, you can pass address(0).

dealAmount Is the amount of the transaction token, if the transaction is not a token, you can pass 0.

_tokenA The contract address of the token pledged by the seller

_tokenB The contract address of the token pledged by the buyer

_tokenAAmount The number of tokens pledged by the seller

_tokenBAmount The number of tokens pledged by the buyer

time Current timestamp

```
 function createDeal(address _personA, address _personB, address _dealToken, uint256 dealAmount, address _tokenA, address _tokenB, uint256 _tokenAAmount, uint256 _tokenBAmount, uint256 time) public returns (address businessDeal) 
```

### Get Deal interface

```
 function getDeal(address _personA, address _personB, address _dealToken, uint256 dealAmount, address _tokenA, address _tokenB, uint256 _tokenAAmount, uint256 _tokenBAmount, uint256 time) public view override returns(address)
```

## BusinessDeal contract API

>  Deal Code


Called when the seller creates a contract through the factory, initializes a deal, and transfers the seller’s margin and transaction token to the deal contract account at the same time

```
function initialize(address _personA, address _personB, address _dealToken, uint256 _dealAmount, address _tokenA, address _tokenB, uint256 _tokenAAmount, uint256 _tokenBAmount, uint256 _time) public
```

Buyer pledges margin to Deal contract

```
function deposit () public 
```

The seller agrees to complete the transaction

```
function accept()
```

Cancel the transaction. When the status is 1, the seller can unilaterally cancel it. When the status is 2, both the seller and the buyer need to call to cancel

```
function cancel() 
```

Check the current status. When the seller creates the disease pledge deposit, the status is 1, and when the buyer pledges the deposit, the status is 2. When the transaction is cancelled or completed, the status is 0.

```
function currentState()
```