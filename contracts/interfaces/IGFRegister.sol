// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

struct Registration {
    string name;
    address addr; 
    uint256 version; 
}

interface IGFRegister { 

    function isSet(string memory _name) view external returns (bool _isSet);
    
    function getName(address _address) view external returns (string memory _name);

    function getAddress(string memory _name) view external returns (address _address);

    function getNames() view external returns (string [] memory _names);

    function getConfig() view external returns (Registration [] memory _registrations);
}