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
        game = new Game(
            INITIAL_CLAIM_FEE,
            GRACE_PERIOD,
            FEE_INCREASE_PERCENTAGE,
            PLATFORM_FEE_PERCENTAGE
        );
        vm.stopPrank();
    }

    function testConstructor_RevertInvalidGracePeriod() public {
        vm.expectRevert("Game: Grace period must be greater than zero.");
        new Game(
            INITIAL_CLAIM_FEE,
            0,
            FEE_INCREASE_PERCENTAGE,
            PLATFORM_FEE_PERCENTAGE
        );
    }

    /*//////////////////////////////////////////////////////////////
                              AUDIT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_revert_claimThrone() public {
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

    function _claimThroneByUser(address _player, uint256 _fee) internal {
        vm.deal(_player, _fee);
        vm.startPrank(_player);
        game.claimThrone{value: _fee}();
        vm.stopPrank();
    }

    function test_claimThrone_ref() public {
        _claimThroneByUser(player1, INITIAL_CLAIM_FEE);

        uint256 claimTimestamp = block.timestamp;
        assertEq(
            address(game).balance,
            INITIAL_CLAIM_FEE,
            "Contract should have balance equal to INITIAL_CLAIM_FEE"
        );
        uint256 expectedPlatformFee = (INITIAL_CLAIM_FEE *
            PLATFORM_FEE_PERCENTAGE) / 100;
        assertEq(
            game.pot(),
            INITIAL_CLAIM_FEE - expectedPlatformFee,
            "Pot should be equal to INITIAL_CLAIM_FEE - expectedPlatformFee"
        );
        // Check that the player is now the king
        assertEq(
            game.currentKing(),
            player1,
            "Player 1 should be current king"
        );
        assertEq(
            game.lastClaimTime(),
            claimTimestamp,
            "Last claim time should match the block timestamp, "
        );
        assertEq(
            game.gameRound(),
            1,
            "Game round should be incremented by 1 after claiming"
        );
        assertEq(
            game.totalClaims(),
            1,
            "Total claims should be incremented by 1 after claiming"
        );
        assertEq(
            game.gameEnded(),
            false,
            "Game should not be ended after claiming"
        );
    }

    // this function will test the game round functionality with a winner
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
        // increase time to finish the game
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

    function test_percentages() public {
        uint256 sentAmount = 100 ether;
        uint256 platformFeePercentage = 10;
        uint256 currentPlatformFee = 0;
        currentPlatformFee = (sentAmount * platformFeePercentage) / 100;
        console2.log("sentAmount: %s [%e]", sentAmount, sentAmount);
        console2.log(
            "platformFeePercentage: %s [%e]",
            platformFeePercentage,
            platformFeePercentage
        );
        console2.log(
            "currentPlatformFee: %s [%e]",
            currentPlatformFee,
            currentPlatformFee
        );
    }

    function test_previousKingPayout() public {
        // uint256 sentAmount = 1.5 ether;
        // uint256 previousKingPayout = 0;
        // uint256 platformFeePercentage = 1000;
        // uint256 currentPlatformFee = 0;

        // // Calculate platform fee
        // currentPlatformFee = (sentAmount * platformFeePercentage) / 10_000;

        // // Defensive check to ensure platformFee doesn't exceed available amount after previousKingPayout
        // if (currentPlatformFee > (sentAmount - previousKingPayout)) {
        //     currentPlatformFee = sentAmount - previousKingPayout;
        // }
        // console2.log("sentAmount: %s [%e]", sentAmount, sentAmount);
        // console2.log(
        //     "platformFeePercentage: %s [%e]",
        //     platformFeePercentage,
        //     platformFeePercentage
        // );
        // console2.log(
        //     "previousKingPayout: %s [%e]",
        //     previousKingPayout,
        //     previousKingPayout
        // );
        // console2.log(
        //     "condition bool: %s ",
        //     currentPlatformFee > (sentAmount - previousKingPayout)
        // );
        // console2.log(
        //     "condition calc: %s [%e]",
        //     sentAmount - previousKingPayout,
        //     sentAmount - previousKingPayout
        // );
        // console2.log(
        //     "currentPlatformFee: %s [%e]",
        //     currentPlatformFee,
        //     currentPlatformFee
        // );

        // claim throne as player 1
        _claimThroneByUser(player1, INITIAL_CLAIM_FEE);
        assertEq(game.currentKing(), player1);
        assertEq(game.getPreviousPayout(player1), INITIAL_CLAIM_FEE);

        uint256 _cpfp1 = (INITIAL_CLAIM_FEE * game.platformFeePercentage()) /
            100;

        console2.log(
            "Player1 %s : %e",
            game.getPreviousPayout(player1),
            game.getPreviousPayout(player1)
        );
        console2.log("Player1 _cpf %s : %e", _cpfp1, _cpfp1);

        // claim throne as player 2
        // uint256 _newFee = game.claimFee();
        // uint256 expectedPlayerTwoPayout = _newFee

        _claimThroneByUser(player2, game.claimFee());
        uint256 claimFeePlayer2 = game.claimFee();
        uint256 _cpfp2 = (claimFeePlayer2 * game.platformFeePercentage()) / 100;
        console2.log("Player2 _cpf %s : %e", _cpfp2, _cpfp2);
        console2.log(
            "Player2 claimFee %s : %e",
            claimFeePlayer2,
            claimFeePlayer2
        );
        uint256 _conditionCalc = claimFeePlayer2 -
            game.getPreviousPayout(player1);
        console2.log("Condition  %s : %e", _conditionCalc, _conditionCalc);
        console2.log(
            "Condition bool: %s",
            _cpfp2 > _conditionCalc
        );

        console2.log(
            "Player2 %s : %e",
            game.getPreviousPayout(player2),
            game.getPreviousPayout(player2)
        );
    }
}
