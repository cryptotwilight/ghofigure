// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

interface IGFPriceFeed {

    function getPrice(string memory _baseSymbol, string memory _quoteSymbol) view external returns (uint256 _price);

}