// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BondingMarket.sol";

contract BondingMarketFactory {
    BondingMarket[] public markets;

    event MarketCreated(address marketAddress);

    function createMarket(
        uint256 _bettingEndTime,
        string[] memory _optionNames
    ) public {
        BondingMarket market = new BondingMarket(
            _bettingEndTime,
            _optionNames,
            msg.sender
        );
        markets.push(market);
        emit MarketCreated(address(market));
    }

    function getMarkets() public view returns (BondingMarket[] memory) {
        return markets;
    }
}
