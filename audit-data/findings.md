## Commit Hash: 

## Development Environment Setup
- Solc Version: 0.8.20 or higher
- Chain(s) to deploy contract to: Any EVM-compatible chain.
- Tokens: ETH (native currency of the blockchain).

## Lines of Code 

```
+-------+-----+-----+------+
|       | src | dep | test |
+-------+-----+-----+------+
| loc   | 372 | 128 | 0    |
| sloc  | 180 | 52  | 0    |
| cloc  | 140 | 59  | 0    |
| Total | 692 | 239 | 0    |
+-------+-----+-----+------+
```

## Protocol description:

"King of the Hill" style game where players vie for the title of "King" by paying an increasing fee. The game's core mechanic revolves around a grace period for each round: 

- players can `claimThrone()` sending the required `claimFee`.
- if no new player claims the throne before this period expires.
- the current King wins the entire accumulated prize pot.

## Roles

- Owner: Deployer of the protocol, can trigger the following functions:
    - `resetGame()`:  Allows the contract owner to reset the game for a new round.
    - `updateGracePeriod()`: Allows the contract owner to update the grace period.
    - `updateClaimFeeParameters()`: Allows the contract owner to update the initial claim fee and fee increase percentage.
    - `updatePlatformFeePercentage()`: Allows the contract owner to update the platform fee percentage.
    - `withdrawPlatformFees()`: Allows the contract owner to withdraw accumulated platform fees.

## Scope 

```bash
src/
+-- Game.sol
```

## Findings

## HIGH

### [H-1] S - Insufficient Test Coverage

**Submit**: https://codehawks.cyfrin.io/c/2025-07-last-man-standing/s/cmdrvfecb0003jp04cyovb6a6

**Description**: 

Insufficient testing, while not a specific vulnerability, implies a high probability of additional undiscovered vulnerabilities and bugs. It also exacerbates multiple interrelated risk factors in a complex code base. This includes a lack of complete, implicit specification of the functionality and exact expected behaviors that tests normally provide, which increases the chances of correctness issues being missed. It also requires more effort to establish basic correctness and reduces the effort spent exploring edge cases, thereby increasing the chances of missing complex issues.

```
╭-------------------+-----------------+----------------+---------------+--------------╮
| File              | % Lines         | % Statements   | % Branches    | % Funcs      |
+=====================================================================================+
| script/Game.s.sol | 0.00% (0/15)    | 0.00% (0/14)   | 100.00% (0/0) | 0.00% (0/2)  |
|-------------------+-----------------+----------------+---------------+--------------|
| src/Game.sol      | 14.89% (14/94)  | 15.85% (13/82) | 12.82% (5/39) | 6.67% (1/15) |
|-------------------+-----------------+----------------+---------------+--------------|
| Total             | 12.84% (14/109) | 13.54% (13/96) | 12.82% (5/39) | 5.88% (1/17) |
╰-------------------+-----------------+----------------+---------------+--------------╯
```

Moreover, the lack of repeated automated testing of the full specification increases the chances of introducing breaking changes and new vulnerabilities. This applies to both previously audited code and future changes to currently audited code. Underspecified interfaces and assumptions increase the risk of subtle integration issues which testing could reduce by enforcing an exhaustive specification.

**Recommended Mitigation**: To address these issues, consider implementing a comprehensive multi-level test suite. Such a test suite should comprise contract-level tests with 95%-100% coverage, per chain/layer deployment, and integration tests that test the deployment scripts as well as the system as a whole, along with per chain/layer fork tests for planned upgrades. Crucially, the test suite should be documented in such a way that a reviewer can set up and run all these test layers independently of the development team. Some existing examples of such setups can be suggested for use as reference in a follow-up conversation. In addition, consider merging all the test suites into a single one for better maintenance. Implementing such a test suite should be of very high priority to ensure the system's robustness and reduce the risk of vulnerabilities and bugs.

### [H-2] S - The `Game::claimThrone` function will always revert if called by a player who is not the current king, leading to a loss of control over the game.

**Submit**: https://codehawks.cyfrin.io/c/2025-07-last-man-standing/s/cmdrxpuxv0005l4049gxrd99b

**Description**:

The `Game::claimThrone` function checks if the caller is the current king using the `Game::currentKing` variable. If not, it will revert with a message indicating that the player is not the current king. This ensures that only the current king can claim the throne.

```javascript
    function claimThrone() external payable gameNotEnded nonReentrant {
        require(msg.value >= claimFee, "Game: Insufficient ETH sent to claim the throne.");
@>        require(msg.sender == currentKing, "Game: You are already the king. No need to re-claim.");

```

**Impact**: No one can enter the game, since the `Game::currentKing` variable starts at `address(0)`.

**Proof of Concept**: (Proof of code)

The following unit test will demonstrate how the function reverts when called by a player who is not the `Game::currentKing` and `Game::currentKing` value is `address(0)`:

```javascript
    function test_claimThrone() public {
        address _currentKing = game.currentKing();
        console2.log("Current King: ", _currentKing);
        // Check that the current king is zero before claiming
        assertEq(
            _currentKing,
            address(0),
            "Current King should be zero before claiming"
        );
        vm.startPrank(player1);
        vm.expectRevert("Game: You are already the king. No need to re-claim.");
        game.claimThrone{value: INITIAL_CLAIM_FEE}();
        vm.stopPrank();
    }
```

**Recommended Mitigation**: Replace the strict equality with a more robust comparison, such as:

```diff
- require(msg.sender == currentKing, "Game: You are already the king. No need to re-claim.");
+ require(msg.sender != currentKing, "Game: You are already the king. No need to re-claim.");
```


## MEDIUM


## LOW

### [L-1] S - Unlocked Pragma.

**Submit**: https://codehawks.cyfrin.io/c/2025-07-last-man-standing/s/cmdrvscrz0005k404pd47po8f

**Description**: Every Solidity file specifies in the header a version number of the format pragma solidity (^)0.8.*. The caret (^) before the version number implies an unlocked pragma, meaning that the compiler will use the specified version and above, hence the term "unlocked".

In contract `Game.sol`, the following pragma version is used: `^0.8.20`.

**Impact**: Unexpected behavior.

**Recommended Mitigation**: For consistency and to prevent unexpected behavior in the future, it is recommended to remove the caret to lock the file onto a specific Solidity version.


### [L-2] `nonReentrant` should be the first modifier at `Game::withdrawPlatformFees`.

**Description**:

To protect against reentrancy in other modifiers, the `nonReentrant` modifier should be the first modifier in the list of modifiers.

The `Game::withdrawPlatformFees` function is defined as follows:

```javascript
    function withdrawPlatformFees() external onlyOwner nonReentrant {
```

**Recommended Mitigation**: Place the `nonReentrant` modifier as the first modifier in the list of modifiers of the `Game::withdrawPlatformFees` function.

```javascript
    function withdrawPlatformFees() external nonReentrant onlyOwner {
```

## INFORMATIONAL

### [I-1] Missing `makefile` for better build process and maintenance.

**Description**:

The project lacks a `makefile`, which can lead to issues with building and maintaining the project. A `makefile` can automate tasks such as compiling contracts, running tests, and deploying the contract to a test network

**Impact**: Without knowing the exact versions of tools and dependencies used by the time of development, it may be difficult to update or maintain the project and could lead to unexpected issues during development and deployment in the future.

**Recommended Mitigation**: Create a `makefile` for the project and include commands for compiling contracts, running tests, and deploying the contract to a test network. This will help in maintaining the project and reducing the risk of errors during development and deployment. 

Here is a simple example for a makefile for a Solidity project:

```makefile
-include .env

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install foundry-rs/forge-std@v1.10.0 --no-commit && forge install openzeppelin/openzeppelin-contracts@v5.4.0 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

snapshot :; forge snapshot

format :; forge fmt
```


### [I-2] Missing `remmappings` values in `foundry.toml` configuration file for better maintainability.

**Description**: The `remappings` values in the `foundry.toml` configuration file should include all the remappings needed for better maintainability and readability of the codebase. This will help in reducing the chances of errors and making it easier for other developers to understand the project.

Although it contains the `remappings.txt` file, it should be included in the `foundry.toml` configuration file as well. 

**Recommended Mitigation**: Add all the remappings needed to the `foundry.toml` configuration file.

Short example for the remappings used on the project.
```toml
remappings = [
    "@openzeppelin/=lib/openzeppelin-contracts/"
]
```

### [I-3] Unnecesary usage of `nonReentrant` modifier at `Game::claimThrone`.

**Description**:

the `Game::claimThrone` payable function is used to pay the `claimFee` in order to become the `currentKing` of the actual round. This function does not make any external calls and can be safely called without the `nonReentrant` modifier.

Generally there is no need to use the `nonReentrant` modifier on a function that only deposits ETH, as long as it does not make any external calls.

**Recommended Mitigation**: Remove the `nonReentrant` modifier from the `Game::claimThrone` funtion.

## OPTIMIZATIONS

### [O-1] Replace `require` Statements with Custom Errors, only if solc version is 0.8.4 or higher.

**Description**: As stated in the official release of (Solidity 0.8.4)[https://soliditylang.org/blog/2021/04/21/custom-errors/], utilizing custom errors can reduce runtime and deployment costs, as indicated by the following benchmark, while also improving clarity in error handling.

**Recommended Mitigation**: Consider update to solidity version 0.8.4 or higher and replacing all require statements with custom errors.

### [O-2] Modifier invoked only once.

**Description**: The `Game::gameEndedOnly` modifier is invoked only once, the logic of it can be moved to the `Game::resetGame` function since it is the only one requiring the modifier logic.

**Recommended Mitigation**: Consider removing the modifier or inlining the logic into the `Game::resetGame` function.

## GAS:

