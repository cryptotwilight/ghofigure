// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IGFVersion.sol";
import "../interfaces/IGiltFundsVault.sol";
import "../interfaces/IGiltContract.sol";
import "../interfaces/IGFRegister.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GiltFundsVault is IGiltFundsVault, IGFVersion { 

    modifier giltContractOnly {
        require(msg.sender == address(giltContract), " gilt contract only ");
        _;
    }

    string constant name = "GILT_FUNDS_VAULT";
    uint256 constant version = 1; 

    address immutable self; 

    uint256 giltId; 
    IGiltContract giltContract; 
    IGFRegister register; 
    IERC20 erc20; 
    uint256 amount; 
    bool committed; 
    bool released; 

    constructor(address _register, uint256 _giltId, address _giltContract){
        register = IGFRegister(_register);
        giltId = _giltId; 
        giltContract = IGiltContract(_giltContract);
        self = address(this);
    }   

    function getName() pure external returns (string memory _name) {
        return name; 
    }

    function getVersion() pure external returns (uint256 _version) {
        return version; 
    }

    function getGiltId() view external returns (uint256 _giltId){
        return giltId; 
    }

    function getGiltContract() view external returns (address _giltContract){
        return address(giltContract);
    }

    function commitFunds( address _token, uint256 _amount) external giltContractOnly returns (bool _committed){
        require(!committed, " vault already committed ");
        committed = true; 
        erc20 = IERC20(_token);
        amount = _amount; 
        erc20.transferFrom(msg.sender, self, amount);
        return true; 
    }

    function releaseFunds() external giltContractOnly returns (bool _released){
        require(committed && !released, " vault already released "); 
        released = true; 
        erc20.approve(msg.sender, amount);
        return true; 
    }
}