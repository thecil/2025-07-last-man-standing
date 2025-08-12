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


### [H-3] Sequential Fee Calculations Lead to Lost Platform Revenue Due to Precision Loss

The `Game` contract calculates fees using sequential percentage calculations with integer division. This approach leads to precision loss as each division operation rounds down, particularly affecting small transactions or those with low percentage fees.

## MEDIUM

## LOW

### [L-1] S - Unlocked Pragma.

**Submit**: https://codehawks.cyfrin.io/c/2025-07-last-man-standing/s/cmdrvscrz0005k404pd47po8f

**Description**: Every Solidity file specifies in the header a version number of the format pragma solidity (^)0.8.*. The caret (^) before the version number implies an unlocked pragma, meaning that the compiler will use the specified version and above, hence the term "unlocked".

In contract `Game.sol`, the following pragma version is used: `^0.8.20`.

**Impact**: Unexpected behavior.

**Recommended Mitigation**: For consistency and to prevent unexpected behavior in the future, it is recommended to remove the caret to lock the file onto a specific Solidity version.


### [L-2] S - `nonReentrant` should be the first modifier at `Game::withdrawPlatformFees`.

**Submit** https://codehawks.cyfrin.io/c/2025-07-last-man-standing/s/cmdtdwtgi0005l504d4xz8dk6

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

### [L-3] S - The `Game::declareWinner` function emits the `Game::GameEnded` with incorrect `pot` value.

**Submit**: https://codehawks.cyfrin.io/c/2025-07-last-man-standing/s/cmdte3sgw0005ia04x9jlbkaf

**Description**:

The `Game::declareWinner` function is used to declare a winner of the actual round once the grace perios has passed and emit the `Game::GameEnded` event.

```javascript
    function declareWinner() external gameNotEnded {
        require(currentKing != address(0), "Game: No one has claimed the throne yet.");
        require(
            block.timestamp > lastClaimTime + gracePeriod,
            "Game: Grace period has not expired yet."
        );

        gameEnded = true;

        pendingWinnings[currentKing] = pendingWinnings[currentKing] + pot;
        pot = 0; // Reset pot after assigning to winner's pending winnings

        emit GameEnded(currentKing, pot, block.timestamp, gameRound);
    }
```

The `pot` global value is reset to zero before emitting the `Game::GameEnded` event, making the `pot` value equals to zero when the event is emitted.

**Proof of Concept**: The `Game::declareWinner` function emits the `Game::GameEnded` event with an incorrect `pot` value. 

The `pot` global value is reset to zero before emitting the `Game::GameEnded` event, making the `pot` value equals to zero when the event is emitted.

The following unit test demonstrate the game round functionality with a winner:

```javascript 
    function _claimThroneByUser(address _player, uint256 _fee) internal {
        vm.startPrank(_player);
        game.claimThrone{value: _fee}();
        vm.stopPrank();
    }

    function test_game_round_with_winner() public {
        // claim throne as player 1
        _claimThroneByUser(player1, INITIAL_CLAIM_FEE);

        vm.warp(block.timestamp + 1 hours);

        uint256 expectedNewFee = game.claimFee() +
            (game.claimFee() * FEE_INCREASE_PERCENTAGE) /
            100;
        // claim throne as player 2
        _claimThroneByUser(player2, game.claimFee());
        assertEq(game.claimFee(), expectedNewFee);

        // will revert if grace period not reached
        vm.expectRevert("Game: Grace period has not expired yet.");
        game.declareWinner();
        // increase time to finish the game round
        vm.warp(
            block.timestamp + game.getRemainingTime() + game.lastClaimTime()
        );
        // declare winner
        game.declareWinner();

        uint256 pendingWinAmount = game.pendingWinnings(player2);
        uint256 player2BalanceBeforeWithdraw = player2.balance;
        // withdraw winnings after declaring winner
        vm.startPrank(player2);
        game.withdrawWinnings();
        vm.stopPrank();
        assertEq(
            player2.balance,
            player2BalanceBeforeWithdraw + pendingWinAmount,
            "Winner should receive the winnings."
        );
        assertEq(game.gameEnded(), true);
    }
```

Executing the test with verbosity level 4, will show the emitted events during its execution and we can verify the incorrect `pot` value on the `Game::GameEnded`.

```bash
forge test --mt test_game_round_with_winner -vvvv
```
The test output will show the emitted event like this:

```
    +- [48801] Game::declareWinner()
    +---- emit GameEnded(winner: player2: [0xEb0A3b7B96C1883858292F0039161abD287E3324], prizeAmount: 0, timestamp: 93602 [9.36e4], round: 1)
```


**Recommended Mitigation**: Snapshot the `pot` value before resetting it and pass it to the emitted event.

```diff
    function declareWinner() external gameNotEnded {
        require(
            currentKing != address(0),
            "Game: No one has claimed the throne yet."
        );
        require(
            block.timestamp > lastClaimTime + gracePeriod,
            "Game: Grace period has not expired yet."
        );

        gameEnded = true;

        pendingWinnings[currentKing] = pendingWinnings[currentKing] + pot;
+       uint256 actualPot = pot;
        pot = 0; // Reset pot after assigning to winner's pending winnings
-       emit GameEnded(currentKing, pot, block.timestamp, gameRound);
+       emit GameEnded(currentKing, actualPot, block.timestamp, gameRound);
    }
```

### [L-4] S - Use named imports.

**Submit**: https://codehawks.cyfrin.io/c/2025-07-last-man-standing/s/cmdxfpv310005ld04w5vzh8t9

**Description**: Use named imports as they offer a number of [advantages](https://ethereum.stackexchange.com/questions/117100/why-do-many-solidity-projects-prefer-importing-specific-names-over-whole-modules/117173#117173) compared to importing the entire namespace.

**Recommended Mitigation**: Replace your imports as follows:

```diff
- import "@openzeppelin/contracts/access/Ownable.sol";
+ import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
```

## INFORMATIONAL

### [I-1] S - Missing `makefile` for better build process and maintenance.

**Submit**: https://codehawks.cyfrin.io/c/2025-07-last-man-standing/s/cmdte9tlc0005k704eqnru3fq

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


### [I-2] S - Missing `remmappings` values in `foundry.toml` configuration file for better maintainability.

**Submit**: https://codehawks.cyfrin.io/c/2025-07-last-man-standing/s/cmdtenke90005ju0461hc308w

**Description**: The `remappings` values in the `foundry.toml` configuration file should include all the remappings needed for better maintainability and readability of the codebase. This will help in reducing the chances of errors and making it easier for other developers to understand the project.

Although it contains the `remappings.txt` file, it should be included in the `foundry.toml` configuration file as well. 

**Recommended Mitigation**: Add all the remappings needed to the `foundry.toml` configuration file.

Short example for the remappings used on the project.
```toml
remappings = [
    "@openzeppelin/=lib/openzeppelin-contracts/"
]
```

### [I-3] S - Unnecesary usage of `nonReentrant` modifier at `Game::claimThrone`.

**Submit**: https://codehawks.cyfrin.io/c/2025-07-last-man-standing/s/cmdxf0vbz0005l1045o6iqu0d

**Description**:

the `Game::claimThrone` payable function is used to pay the `claimFee` in order to become the `currentKing` of the actual round. This function does not make any external calls and can be safely called without the `nonReentrant` modifier.

```javascript
function claimThrone() external payable gameNotEnded nonReentrant {
```

Generally there is no need to use the `nonReentrant` modifier on a function that only deposits ETH, as long as it does not make any external calls.

**Recommended Mitigation**: Remove the `nonReentrant` modifier from the `Game::claimThrone` funtion.

```diff
- function claimThrone() external payable gameNotEnded nonReentrant {
+ function claimThrone() external payable gameNotEnded {
```

### [I-4] S - `Game::withdrawWinnings` should follow CEI

**Submit**: https://codehawks.cyfrin.io/c/2025-07-last-man-standing/s/cmdxgwwwo0005i304vql2udly

**Description**:

The `Game::withdrawWinnings` function does have the `nonReentrant` modifier to avoid reentrancy attacks, which provide security for the function execution.

Still, it's best to keep code clean and follow CEI (Checks, Effects, Interactions).

**Proof of Concept**:

The `Game::withdrawWinnings` function is currently written as follows:

```javascript
    function withdrawWinnings() external nonReentrant {
        uint256 amount = pendingWinnings[msg.sender];
        require(amount > 0, "Game: No winnings to withdraw.");
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Game: Failed to withdraw winnings.");
@>      pendingWinnings[msg.sender] = 0;

        emit WinningsWithdrawn(msg.sender, amount);
    }
```

**Recommended Mitigation**: 

Move the `pendingWinnings[msg.sender] = 0;` before transfering the winnings. This ensures that the `pendingWinnings` is updated before any further operations are performed.

```diff
    function withdrawWinnings() external nonReentrant {
        // Checks
        uint256 amount = pendingWinnings[msg.sender];
        require(amount > 0, "Game: No winnings to withdraw.");
        // Effects
+       pendingWinnings[msg.sender] = 0;
        // Interactions
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Game: Failed to withdraw winnings.");
-       pendingWinnings[msg.sender] = 0;
        emit WinningsWithdrawn(msg.sender, amount);
    }
```


### [I-5] - At `Game::claimThrone` function, the `Game::previousKingPayout` variable is always 0 because it's only set once, making it unnecessary for its check.

**Submit**: 

**Description**: In the `Game::claimThrone` function, the `previousKingPayout` variable is always set to 0 because it's only set once. This makes it unnecessary for this check since the `sentAmount - previousKingPayout` will always be calculated as `msg.value - 0`.

By the moment of this audit, the actual logic does not break the game logic. However, it's a good practice to remove unnecessary variables and checks to improve code readability and maintainability.

```javascript
    function claimThrone() external payable gameNotEnded nonReentrant {
        require(msg.value >= claimFee, "Game: Insufficient ETH sent to claim the throne.");
        require(msg.sender == currentKing, "Game: You are already the king. No need to re-claim.");

        uint256 sentAmount = msg.value;
@>      uint256 previousKingPayout = 0;
        uint256 currentPlatformFee = 0;
        uint256 amountToPot = 0;

        // Calculate platform fee
        currentPlatformFee = (sentAmount * platformFeePercentage) / 100;

        // Defensive check to ensure platformFee doesn't exceed available amount after previousKingPayout
@>      if (currentPlatformFee > (sentAmount - previousKingPayout)) {
@>          currentPlatformFee = sentAmount - previousKingPayout;
        }
        platformFeesBalance = platformFeesBalance + currentPlatformFee;

        // Remaining amount goes to the pot
        amountToPot = sentAmount - currentPlatformFee;
        pot = pot + amountToPot;

        // Update game state
        currentKing = msg.sender;
        lastClaimTime = block.timestamp;
        playerClaimCount[msg.sender] = playerClaimCount[msg.sender] + 1;
        totalClaims = totalClaims + 1;

        // Increase the claim fee for the next player
        claimFee = claimFee + (claimFee * feeIncreasePercentage) / 100;

        emit ThroneClaimed(msg.sender, sentAmount, claimFee, pot, block.timestamp);
    }
```

**Recommended Mitigation**:

1. Remove the `previousKingPayout` variable and harmonize the rest of the function to fulfill this refactor;
2. If the `previousKingPayout` variable is necessary for some reason, consider adding a mapping to keep track of previous king payouts, and retough the logic for the defensive check.

The following code give an example on refactoring the `previousKingPayout` logic by using a mapping, but does not offer any improvements. This is just a starting point and should be further developed based on the specific requirements of the game. 

```diff
+   mapping(address player => uint256 payoutAmount) public s_previousPayouts;

    function claimThrone() external payable gameNotEnded nonReentrant {
        require(msg.value >= claimFee, "Game: Insufficient ETH sent to claim the throne.");
        require(msg.sender == currentKing, "Game: You are already the king. No need to re-claim.");

        uint256 sentAmount = msg.value;
-       uint256 previousKingPayout = 0;
+       uint256 previousKingPayout = s_previousPayouts[currentKing];
        uint256 currentPlatformFee = 0;
        uint256 amountToPot = 0;

        // Calculate platform fee
        currentPlatformFee = (sentAmount * platformFeePercentage) / 100;

        // Defensive check to ensure platformFee doesn't exceed available amount after previousKingPayout
        if (currentPlatformFee > (sentAmount - previousKingPayout)) {
            currentPlatformFee = sentAmount - previousKingPayout;
        }
        platformFeesBalance = platformFeesBalance + currentPlatformFee;

        // Remaining amount goes to the pot
        amountToPot = sentAmount - currentPlatformFee;
        pot = pot + amountToPot;

        // Update game state
+       s_previousPayouts[msg.sender] = sentAmount;
        currentKing = msg.sender;
        lastClaimTime = block.timestamp;
        playerClaimCount[msg.sender] = playerClaimCount[msg.sender] + 1;
        totalClaims = totalClaims + 1;

        // Increase the claim fee for the next player
        claimFee = claimFee + (claimFee * feeIncreasePercentage) / 100;

        emit ThroneClaimed(msg.sender, sentAmount, claimFee, pot, block.timestamp);
    }
```


## OPTIMIZATIONS

### [O-1] S - Replace `require` Statements with Custom Errors, only if solc version is 0.8.4 or higher.

**Submit**: https://codehawks.cyfrin.io/c/2025-07-last-man-standing/s/cmdxg56u40005lf04blpcsbd7

**Description**: As stated in the official release of (Solidity 0.8.4)[https://soliditylang.org/blog/2021/04/21/custom-errors/], utilizing custom errors can reduce runtime and deployment costs, as indicated by the following benchmark, while also improving clarity in error handling.


**Proof of Concept**: 

Lets take the `Game::nonReentrant` modifier as example:

```javascript
    modifier nonReentrant() {
        require(!_locked, "ReentrancyGuard: reentrant call");
        _locked = true;
        _;
        _locked = false;
    }
```
This modifier requires the `_locked` value to be `false` in order to continue its logic.

**Recommended Mitigation**: Consider update to solidity version 0.8.4 or higher and replacing all require statements with custom errors.

Then you can add a custom error like this:

```diff
+    error Game__ReentrancyGuardReentrantCall();

    modifier nonReentrant() {
-       require(!_locked, "ReentrancyGuard: reentrant call");
+       if(_locked){
+           revert Game__ReentrancyGuardReentrantCall();
+       }
        _locked = true;
        _;
        _locked = false;
    }
```

### [O-2] S - Modifier invoked only once.

**Submit**: https://codehawks.cyfrin.io/c/2025-07-last-man-standing/s/cmdxgc8rp0005l804x5w98eu6

**Description**: The `Game::gameEndedOnly` modifier is invoked only once, the logic of it can be moved to the `Game::resetGame` function since it is the only one requiring the modifier logic.

```javascript
    modifier gameEndedOnly() {
        require(gameEnded, "Game: Game has not ended yet.");
        _;
    }
```

**Proof of Concept**:

The original `Game::resetGame` function has a single invocation of the `gameEndedOnly` modifier.

```javascript
    function resetGame() external onlyOwner gameEndedOnly {
        currentKing = address(0);
        lastClaimTime = block.timestamp;
        pot = 0;
        claimFee = initialClaimFee;
        gracePeriod = initialGracePeriod;
        gameEnded = false;
        gameRound = gameRound + 1;
        // totalClaims is cumulative across rounds, not reset here, but could be if desired.

        emit GameReset(gameRound, block.timestamp);
    }
```

**Recommended Mitigation**: Consider removing the modifier or inlining the logic into the `Game::resetGame` function.

```diff
-    modifier gameEndedOnly() {
-        require(gameEnded, "Game: Game has not ended yet.");
-        _;
-    }

-   function resetGame() external onlyOwner gameEndedOnly {
+   function resetGame() external onlyOwner {
+       require(gameEnded, "Game: Game has not ended yet.");
        currentKing = address(0);
        lastClaimTime = block.timestamp;
        pot = 0;
        claimFee = initialClaimFee;
        gracePeriod = initialGracePeriod;
        gameEnded = false;
        gameRound = gameRound + 1;
        // totalClaims is cumulative across rounds, not reset here, but could be if desired.

        emit GameReset(gameRound, block.timestamp);
    }
```

## GAS:

