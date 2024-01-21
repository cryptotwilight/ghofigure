
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "../interfaces/IGFPriceFeed.sol";
import "../interfaces/IGFVersion.sol";
import "../interfaces/IGFRegister.sol";

import "https://github.com/smartcontractkit/chainlink/blob/master/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract GFPriceFeed is IGFPriceFeed, IGFVersion { 

    modifier adminOnly {
        require(msg.sender == register.getAddress(GF_ADMIN_CA), "admin only");
        _;
    }

    string constant name = "RESERVED_GHO_FIGURE_PRICE_FEED";
    uint256 constant version = 1; 

    string constant GF_ADMIN_CA = "RESERVED_GHO_FIGURE_ADMIN";

    IGFRegister register; 

    mapping(string=>string[]) baseListByQuote;
   
    mapping(string=>string[]) quoteListByBase; 

    mapping(string=>mapping(string=>bool)) hasQuoteByBase;
    mapping(string=>mapping(string=>address)) feedContractByQuoteByBase;

    constructor(address _register) {
        register = IGFRegister(_register);
    }

    
    function getName() pure external returns (string memory _name) {
        return name; 
    }

    function getVersion() pure external returns (uint256 _version) {
        return version; 
    }

    function getBaseListByQuote(string memory _quote) view external returns (string[] memory _baseList) {
        return baseListByQuote[_quote];
    }

    function getQuoteListByBase(string memory _base) view external returns (string [] memory _quoteList) {
        return quoteListByBase[_base];
    }

    function getPrice(string memory _baseSymbol, string memory _quoteSymbol) view external returns (uint256 _price){
        require(hasQuoteByBase[_baseSymbol][_quoteSymbol], " unknown pair ");
        (uint80 roundId_, int256 answer_, uint256 startedAt_, uint256 updatedAt_, uint80 answeredInRound_) = AggregatorV3Interface(feedContractByQuoteByBase[_baseSymbol][_quoteSymbol]).latestRoundData();
        _price = uint256(answer_);
    }

    function addChainLinkDataFeed(string memory _base, string memory _quote, address _feedContract) external adminOnly returns (bool _added) {
        require(!hasQuoteByBase[_base][_quote], " already configured ");
        hasQuoteByBase[_base][_quote] = true; 
        quoteListByBase[_base].push(_quote);
        baseListByQuote[_quote].push(_base);
        feedContractByQuoteByBase[_base][_quote] = _feedContract; 
        return true; 
    }
}