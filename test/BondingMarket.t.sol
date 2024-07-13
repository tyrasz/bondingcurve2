// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {BondingMarket} from "../src/BondingMarket.sol";

contract BondingTest is Test {
    BondingMarket public bondingMarket;
    uint256 public bettingEndTime;
    string[] public optionNames;

    function setUp() public {
        // Set betting end time to be 1 day from the current block timestamp
        bettingEndTime = block.timestamp + 1 days;

        // Initialize and populate option names for the betting market
        string[] memory options = new string[](3);
        options[0] = "Option 1";
        options[1] = "Option 2";
        options[2] = "Option 3";

        // Deploy the BondingMarket contract with the computed bettingEndTime and optionNames
        bondingMarket = new BondingMarket(bettingEndTime, options);
    }

    function testSetUp() public view {
        // Check that the betting end time is set correctly
        assertEq(bondingMarket.bettingEndTime(), bettingEndTime);

        // Check that the eventEnded flag is set to false
        assertEq(bondingMarket.eventEnded(), false);

        // Check that the creator of the contract is the deployer of the contract
        assertEq(bondingMarket.creator(), address(this));

        // Check that the option names are set correctly
        assertEq(bondingMarket.optionNames(0), "Option 1");
        assertEq(bondingMarket.optionNames(1), "Option 2");
        assertEq(bondingMarket.optionNames(2), "Option 3");

        // Check that the total bets for each option are set to 0
        // assertEq(bondingMarket.options(0).totalBets, 0);
        // assertEq(bondingMarket.options(1).totalBets, 0);
        // assertEq(bondingMarket.options(2).totalBets, 0);
    }

    function testPlaceBet() public {
        // Your test code here
        // Example: Place a bet and verify it was recorded correctly
        vm.deal(address(this), 1 ether); // Fund the test contract with 1 ETH
        bondingMarket.placeBet{value: 0.003 ether}(0);

        uint256[] memory userBets = bondingMarket.getUserBet(address(this));
        assertEq(userBets[0], 0.003 ether, "Bet amount should be 0.003 ether");
    }
}
