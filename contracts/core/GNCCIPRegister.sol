// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "../interfaces/IGNCCIPRegister.sol";
import "../interfaces/IGFVersion.sol";
import "../interfaces/IGFRegister.sol";



contract GNCCIPRegister is IGNCCIPRegister, IGFVersion { 

    modifier adminOnly { 
        require(msg.sender == register.getAddress(GF_ADMIN_CA), "admin only");
        _;
    }

    string constant name = "RESERVED_GILT_NOTE_CCIP_REGISTER";
    uint256 constant version = 1; 

    string constant GF_ADMIN_CA = "RESERVED_GHO_FIGURE_ADMIN";

    IGFRegister register; 
    uint256 [] chainIds; 
    uint256 [] originChainIds;
    
    mapping(uint256=>bool) knownOriginChainId; 
    mapping(uint256=>address[]) originAddressesByChainId; 
    mapping(address=>CCIPOrigin) originByAddress; 
    mapping(uint256=>mapping(address=>bool)) isAllowedOriginByChainId; 
    mapping(uint256=>CCIPDestination) ccipDestinationByChainId; 

    constructor(address _register) {
        register = IGFRegister(_register);
    }

    function getName() pure external returns (string memory _name) {
        return name; 
    }

    function getVersion() pure external returns (uint256 _version) {
        return version; 
    }

    function getSupportedDestinationChainIds() view external returns (uint256 [] memory _chainIds){
        return chainIds; 
    }

    function getSupportedOriginChainIds() view external returns (uint256 [] memory _chainIds) {
        return originChainIds; 
    }

    function getSupportedOrigins(uint256 _chainId) view external returns (CCIPOrigin [] memory _origins) {
        address [] memory _addresses = originAddressesByChainId[_chainId];
        _origins = new CCIPOrigin[](_addresses.length);
        for(uint256 x = 0; x < _addresses.length; x++) {
            _origins[x] = originByAddress[_addresses[x]];
        }
        return _origins; 
    }

    function getCCIPDestination(uint256 _destinationChainId) view external returns (CCIPDestination memory _destination){
        return ccipDestinationByChainId[_destinationChainId];
    }

    function isAllowedOrigin(CCIPOrigin memory _origin) view external returns (bool isAllowed){
        return isAllowedOriginByChainId[_origin.chainSelector][_origin.source];
    }

    function addCCIPDestination(CCIPDestination memory _destination) external adminOnly returns (bool _added) {
        ccipDestinationByChainId[_destination.chainId] = _destination; 
        chainIds.push(_destination.chainId);
        return true; 
    }

    function addAllowedOrigin(CCIPOrigin memory _origin) external adminOnly returns (bool _added) {
        isAllowedOriginByChainId[_origin.chainSelector][_origin.source] = true;
        originByAddress[_origin.source] = _origin; 
        if(!knownOriginChainId[_origin.chainId]){
            knownOriginChainId[_origin.chainId] = true; 
            originChainIds.push(_origin.chainId);
        }
        return true; 
    }

}