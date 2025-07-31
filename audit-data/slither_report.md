INFO:Detectors:
Reentrancy in Game.withdrawWinnings() (src/Game.sol#244-255):
        External calls:
        - (success,None) = address(msg.sender).call{value: amount}() (src/Game.sol#251-252)
        State variables written after the call(s):
        - pendingWinnings[msg.sender] = 0 (src/Game.sol#254)
        Game.pendingWinnings (src/Game.sol#26-27) can be used in cross function reentrancies:
        - Game.declareWinner() (src/Game.sol#230-241)
        - Game.pendingWinnings (src/Game.sol#26-27)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities

INFO:Detectors:
Game.declareWinner() (src/Game.sol#230-241) uses timestamp for comparisons
        Dangerous comparisons:
        - require(bool,string)(block.timestamp > lastClaimTime + gracePeriod,Game: Grace period has not expired yet.) (src/Game.sol#231-234)
Game.getRemainingTime() (src/Game.sol#331-340) uses timestamp for comparisons
        Dangerous comparisons:
        - block.timestamp >= endTime (src/Game.sol#337-338)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#block-timestamp

INFO:Detectors:
Version constraint ^0.8.20 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
        - VerbatimInvalidDeduplication
        - FullInlinerNonExpressionSplitArgumentEvaluationOrder
        - MissingSideEffectsOnSelectorAccess.
It is used by:
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/access/Ownable.sol#4)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/Context.sol#4)
        - ^0.8.20 (src/Game.sol#2-3)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-versions-of-solidity

INFO:Detectors:
Low level call in Game.withdrawWinnings() (src/Game.sol#244-255):
        - (success,None) = address(msg.sender).call{value: amount}() (src/Game.sol#251-252)
Low level call in Game.withdrawPlatformFees() (src/Game.sol#314-325):
        - (success,None) = address(owner()).call{value: amount}() (src/Game.sol#321-322)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#low-level-calls

INFO:Detectors:
Game.initialGracePeriod (src/Game.sol#22-23) should be immutable 
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#state-variables-that-could-be-declared-immutable
INFO:Slither:. analyzed (3 contracts with 99 detectors), 7 result(s) found