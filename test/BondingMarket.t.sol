// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {BondingMarket} from "../src/BondingMarket.sol";

contract BondingTest is Test {
    Counter public counter;
    uint256 public bettingEndTime;
    string[] public optionNames;

    function setUp() public {
        BondingMarket bondingMarket = new BondingMarket();
    }

    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}
