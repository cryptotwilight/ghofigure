// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "../interfaces/IGFRegister.sol";
import "../interfaces/IGFVersion.sol";
import "../interfaces/IGiltVault.sol";
import "../interfaces/IGiltContract.sol";

import {Gilt} from "../interfaces/IGFStructs.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; 

contract GiltVault is IGiltVault, IGFVersion { 

    modifier senderOnly { 
        require(msg.sender == register.getAddress(SENDER_CA), "Cross Chain Gilt Sender Only");
        _;
    }

        modifier receiverOnly { 
        require(msg.sender == register.getAddress(RECEIVER_CA), "Cross Chain Gilt Receiver Only");
        _;
    }

    string constant name = "RESERVED_GILT_VAULT";
    uint256 constant version = 1;

    string constant SENDER_CA = "RESERVED_GILT_NOTE_CCIP_SENDER";
    string constant RECEIVER_CA = "RESERVED_GILT_NOTE_CCIP_RECEIVER";


    IGFRegister register;
    address immutable self; 

    uint256 [] vaultIds; 

    mapping(uint256=>Gilt) giltByVaultId; 
    mapping(uint256=>bool) isVaultedByVaultId; 


    constructor(address _register) {
        register = IGFRegister(_register);
        self = address(this);
    }

    function getName() pure external returns (string memory _name) {
    return name; 
    }

    function getVersion() pure external returns (uint256 _version) {
    return version; 
    }

    function getGilt(uint256 _vaultId) view external returns (Gilt memory _gilt){
        return giltByVaultId[_vaultId]; 
    }

    function isVaulted(uint256 _vaultId) view external returns (bool _isVaulted) {
        return isVaultedByVaultId[_vaultId];
    }

    function vaultGilt(uint256 _giltId, address _giltContract) external senderOnly returns (uint256 _giltVaultId){
        IERC721 erc721_ = IERC721(_giltContract);
        erc721_.transferFrom(msg.sender, self, _giltId);
        _giltVaultId = getIndex(); 
        vaultIds.push(_giltVaultId);
        isVaultedByVaultId[_giltVaultId] = true; 
        giltByVaultId[_giltVaultId] = IGiltContract(_giltContract).getGilt(_giltId);
        return _giltVaultId; 
    }

    function releaseGilt(uint256 _giltVaultId) external receiverOnly returns (address _giltContract, uint256 _giltId){
        Gilt memory gilt_ = giltByVaultId[_giltVaultId];
        _giltContract = gilt_.giltContract; 
        _giltId = gilt_.id; 
        IERC721(_giltContract).approve(msg.sender, gilt_.id);
        return (_giltContract, _giltId);
    }

    //================================================= INTERNAL =================================================================
    uint256 index; 

    function getIndex() internal returns (uint256 _index) {
        _index = index++; 
        return _index; 
    }
}