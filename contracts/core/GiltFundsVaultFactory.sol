// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "../interfaces/IGiltFundsVaultFactory.sol";
import "../interfaces/IGFVersion.sol";
import "../interfaces/IGFRegister.sol";

import "./GiltFundsVault.sol";

contract GiltFundsVaultFactory is IGiltFundsVaultFactory, IGFVersion { 

    modifier giltContractOnly {
        require(msg.sender == register.getAddress(GILT_CONTRACT_CA), " gilt contracct only ");
        _;
    }


    string constant name = "RESERVED_VAULT_FACTORY";
    uint256 constant version = 1; 

    string constant GILT_CONTRACT_CA = "RESERVED_GILT_CONTRACT"; 

    IGFRegister register; 

    address [] vaults; 
    mapping(address=>bool) knownVault; 

    constructor(address _register) {
        register = IGFRegister(_register);
    }
    function getName() pure external returns (string memory _name) {
        return name; 
    }

    function getVersion() pure external returns (uint256 _version) {
        return version; 
    }
    function getVaults() view external returns (address [] memory _vaults) {
        return vaults; 
    }

    function isKnownVault(address _vault) view external returns (bool _isKnown) {
        return knownVault[_vault];
    }

    function getGiltFundsVault(uint256 _giltId, address _giltContract) external giltContractOnly returns (address _vault){
        _vault = address(new GiltFundsVault(address(register), _giltId, _giltContract));
        vaults.push(_vault);
        knownVault[_vault];
        return (_vault);
    }

}