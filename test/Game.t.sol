// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {Game} from "../src/Game.sol";

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

    function test_claimThrone() public {
        address _currentKing = game.currentKing();
        console2.log("Current King: ", _currentKing);
        assertEq(
            _currentKing,
            address(0),
            "Current King should be zero before claiming"
        ); // Check that the current king is zero

        vm.startPrank(player1);
        vm.expectRevert("Game: You are already the king. No need to re-claim.");
        game.claimThrone{value: INITIAL_CLAIM_FEE}();
        vm.stopPrank();

        // uint256 claimTimestamp = block.timestamp;
        // assertEq(address(game).balance, INITIAL_CLAIM_FEE, "Contract should have balance equal to INITIAL_CLAIM_FEE"); // Check that the player received the initial claim fee
        // assertEq(game.currentKing(), player1, "Player 1 should be current king"); // Check that the player is now the king
        // assertEq(game.lastClaimTime(), claimTimestamp, "Last claim time should match the block timestamp, "); // Check that
    }
}
