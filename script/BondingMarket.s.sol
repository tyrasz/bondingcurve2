// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {BondingMarket} from "../src/BondingMarket.sol";

contract BondingMarketScript is Script {
    BondingMarket public bondingMarket;
    uint256 public bettingEndTime;
    string[] public optionNames;

    function setUp() public {
        bettingEndTime = block.timestamp + 1 days;

        // Initialize and populate option names for the betting market
        optionNames = new string[](3);
        optionNames[0] = "Option 1";
        optionNames[1] = "Option 2";
        optionNames[2] = "Option 3";
    }

    function run() public {
        vm.startBroadcast();

        // Deploy the BondingMarket contract with the computed bettingEndTime and optionNames
        bondingMarket = new BondingMarket(bettingEndTime, optionNames);

        vm.stopBroadcast();
    }
}
