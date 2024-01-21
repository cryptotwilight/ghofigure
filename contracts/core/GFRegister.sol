// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "../interfaces/IGFRegister.sol";
import "../interfaces/IGFVersion.sol";

contract GFRegister is IGFRegister, IGFVersion {

    modifier adminOnly { 
        require(msg.sender == admin, "admin only");
        _;
    }

    string constant name = "RESERVED_GHO_FIGURE_REGISTER";
    uint256 constant version = 4;

    string constant GF_ADMIN_CA = "RESERVED_GHO_FIGURE_ADMIN";


    address immutable self; 

    address admin; 
    uint256 immutable chainId; 

    string [] names; 
    mapping(string=>bool) knownName; 
    mapping(string=>address) addressByName; 
    mapping(address=>string) nameByAddress; 
    mapping(string=>Registration) registrationByName; 
    mapping(address=>Registration) registrationByAddress; 

    constructor(address _admin, uint256 _chainId) {
        admin = _admin; 
        self = address(this);
        addAddressInternal(name, self, version);
        addAddressInternal(GF_ADMIN_CA, _admin, 0);
        chainId = _chainId; 
    }
    
    function getName() pure external returns (string memory _name) {
        return name; 
    }

    function getVersion() pure external returns (uint256 _version) {
        return version; 
    }

    function getChainId() view external returns (uint256 _chainId) {
        return chainId; 
    }

    function getName(address _address) view external returns (string memory _name){
        return nameByAddress[_address];
    }

    function getAddress(string memory _name) view external returns (address _address){
        return addressByName[_name];
    }

    function getNames() view external returns (string [] memory _names){
        return names; 
    }

    function isSet(string memory _name) view external returns (bool _isSet) {
        return knownName[_name];
    }


    function getConfig() view external returns (Registration [] memory _registrations){
        _registrations = new Registration[](names.length);
        for(uint256 x = 0; x < _registrations.length; x++) {
            string memory name_ = names[x];
            _registrations[x] = registrationByName[name_];
        }        
        return _registrations; 
    }


    function addAddress(string memory _name, address _address, uint256 _version) external adminOnly returns (bool _added) {
        return addAddressInternal(_name, _address, _version);
    }   

    function addGFVersionAddress(address _address) external adminOnly returns (bool _added) {
        IGFVersion v_ = IGFVersion(_address);
        return addAddressInternal(v_.getName(), _address, v_.getVersion());
    }

    //========================================= INTERNAL ==========================================================================

    function addAddressInternal(string memory _name, address _address, uint256 _version) internal returns (bool _added) {
        nameByAddress[_address] = _name; 
        addressByName[_name] = _address;
        if(!knownName[_name]) { 
            names.push(_name);
            knownName[_name] = true; 
        }
        registrationByName[_name] = Registration({
                                                    name : _name, 
                                                    addr : _address, 
                                                    version : _version
                                                 });
        registrationByAddress[_address] = registrationByName[_name];
        return true; 
    }

}