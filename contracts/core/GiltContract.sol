// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IGiltContract.sol";
import "../interfaces/IGFVersion.sol";
import "../interfaces/IGFRegister.sol";
import "../interfaces/IGiltFundsVaultFactory.sol";
import "../interfaces/IGiltFundsVault.sol";

contract GiltContract is ERC721, IGiltContract, IGFVersion {
    
    string constant nme = "RESERVED_GILT_CONTRACT";
    uint256 constant version = 1; 

    string constant VAULT_FACTORY_CA = "RESERVED_VAULT_FACTORY";

    address immutable self; 

    IGFRegister register; 

    uint256 [] giltIds; 
    mapping(uint256=>Gilt) giltById; 
    mapping(uint256=>bool) knownGiltId; 
    
    
    constructor(address _register) ERC721("GiltContract", "GILT"){
        register = IGFRegister(_register);
        self = address(this);
    }   

    function _baseURI() internal pure override returns (string memory) {
        return "https://www.blockstarlogic.xyz/gilts";
    }
    function getName() pure external returns (string memory _name) {
        return nme; 
    }

    function getVersion() pure external returns (uint256 _version) {
        return version; 
    }

    function getGiltIds() view external returns (uint256 [] memory _giltIds){
        return giltIds;
    }

    function getGilt(uint256 _giltId) view external returns (Gilt memory _gilt){
        return giltById[_giltId];
    }

    function isKnownGilt(uint256 _giltId) view external returns (bool _isKnownGilt){
        return knownGiltId[_giltId];
    }

    function mintGilt(ProtoGilt memory _pGilt) external returns (uint256 _giltId){
        
        _giltId = getIndex(); 
        knownGiltId[_giltId] = true; 
        giltIds.push(_giltId);
        IERC20 erc20_ = IERC20(_pGilt.erc20);
        erc20_.transferFrom(msg.sender, self, _pGilt.amount);

        IGiltFundsVault fVault_ = IGiltFundsVault(IGiltFundsVaultFactory(register.getAddress(VAULT_FACTORY_CA)).getGiltFundsVault(_giltId, self));
        erc20_.approve(address(fVault_), _pGilt.amount);
        fVault_.commitFunds(_pGilt.erc20, _pGilt.amount);
        giltById[_giltId] = createGilt(_giltId, _pGilt.amount, _pGilt.erc20, address(fVault_));

        _safeMint(_pGilt.owner, _giltId);
        return _giltId; 
    }

    function dissolveGilt(uint256 _giltId, address _fundsTo) external returns (address _erc20, uint256 _amount){
        transferFrom(msg.sender, self, _giltId);
        Gilt memory _gilt = giltById[_giltId];
        _burn(_giltId);
        IGiltFundsVault(_gilt.giltVault).releaseFunds(); 
        IERC20 erc20_ = IERC20(_gilt.erc20);
        erc20_.transferFrom(_gilt.giltVault, self, _gilt.amount);
        erc20_.transfer(_fundsTo, _gilt.amount);
        return (_gilt.erc20, _gilt.amount);
    }

    //================================= INTERNAL ======================================================

    function createGilt(uint256 _giltId, uint256 _amount, address _erc20, address _giltFundsVault)view  internal returns (Gilt memory _gilt) {
        return Gilt({
                        id : _giltId,  
                        amount : _amount, 
                        erc20 : _erc20, 
                        giltVault : _giltFundsVault, 
                        giltContract : self
                    });
    }


    uint256 index = 0; 

    function getIndex() internal returns (uint256 _index) {
        _index = index++;
        return _index; 
    }
}
