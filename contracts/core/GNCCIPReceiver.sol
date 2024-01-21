// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "../interfaces/IGFVersion.sol";
import "../interfaces/IGNCCIPReceiver.sol";
import "../interfaces/IGFRegister.sol";
import "../interfaces/IGhoGNPool.sol";
import "../interfaces/IGNCCIPRegister.sol";

import {Gilt} from "../interfaces/IGFStructs.sol";

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/IERC20.sol";

contract GNCCIPReceiver is CCIPReceiver, IGNCCIPReceiver, IGFVersion {

    modifier adminOnly { 
        require(msg.sender == register.getAddress(GF_ADMIN_CA), " admin only ");
        _;
    }

    modifier poolOnly {
        require(msg.sender == register.getAddress(GHO_GN_POOL_CA), "Gho Gilt Pool only");
        _;
    }

    string constant name = "RESERVED_GILT_NOTE_CCIP_RECEIVER";
    uint256 constant version = 3; 

    string constant GHO_GN_POOL_CA = "RESERVED_GHO_GILT_NOTE_POOL";
    string constant GN_CCIP_REGISTER_CA = "RESERVED_GILT_NOTE_CCIP_REGISTER";
    string constant GF_ADMIN_CA = "RESERVED_GHO_FIGURE_ADMIN";


    IGFRegister register; 

    int256 [] gnIds; 
    mapping(int256=>bool) gnIsLocked; 
    mapping(int256=>GiltNote) gnById;
    mapping(address=>int256[]) gnIdsByOwner; 

    constructor(address _register, address _router) CCIPReceiver(_router) {
        register = IGFRegister(_register);
    }

    function getName() pure external returns (string memory _name) {
        return name; 
    }

    function getVersion() pure external returns (uint256 _version) {
        return version; 
    }

    /// handle a received message
    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal override  {
        IGNCCIPRegister ccipRegister = IGNCCIPRegister(register.getAddress(GN_CCIP_REGISTER_CA));
        address source_ = abi.decode(any2EvmMessage.sender, (address));
        uint64 chainSelector_ = any2EvmMessage.sourceChainSelector; 
        CCIPOrigin memory origin_ = CCIPOrigin({
                                        chainId : 0,
                                        source : source_, 
                                        chainSelector : chainSelector_                                     
                                     });
        if(ccipRegister.isAllowedOrigin(origin_)){

            GiltNote memory gn_ = abi.decode(any2EvmMessage.data, (GiltNote)); // abi-decoding of the sent text
            processGiltNoteInternal(gn_);
        }
       
    }


    function getAllRecievedGiltNoteIds() view external returns (int256 [] memory _gnIds){
        return gnIds; 
    }

    function getGNIds(address _owner) view external returns (int256 [] memory _gnIds){
        return gnIdsByOwner[_owner];
    }

    function getGN(int256 _gnId) view external returns (GiltNote memory _gn){
        return gnById[_gnId];
    }

    function lockGN(int256 _gnId) external poolOnly returns (bool _locked){
        gnIsLocked[_gnId] = true; 
        return true; 
    }

    function unlockGN(int256 _gnId) external poolOnly returns (bool _unlocked){
        gnIsLocked[_gnId] = false; 
        return true;
    }

    function isLocked(int256 _gnId) view external returns (bool _isLocked){
        return gnIsLocked[_gnId];
    }

    function injectGiltNote(GiltNote memory _gn) external adminOnly returns (bool _injected) {
        processGiltNoteInternal(_gn);
        return true; 
    }


    //================================ INTERNAL ================================================== 


    function processGiltNoteInternal(GiltNote memory _gn) internal {
        int256 localId_ = getIndex(); 
        gnIds.push(localId_);
        gnIdsByOwner[_gn.owner].push(localId_);
        gnById[localId_] = GiltNote({
                                        id : _gn.id, 
                                        originChainId : _gn.originChainId, 
                                        amount : _gn.amount,  
                                        erc20 : _gn.erc20,  
                                        symbol : _gn.symbol, 
                                        decimals : _gn.decimals,
                                        owner : _gn.owner, 
                                        createDate : _gn.createDate, 
                                        giltContract : _gn.giltContract, 
                                        giltVault : _gn.giltVault, 
                                        localId : localId_ 
                                    });
        IGhoGNPool(register.getAddress(GHO_GN_POOL_CA)).notifyGNArrival(gnById[localId_]);
    }

    int256 index = 0; 

    function getIndex() internal returns (int256 _index) {
        _index = index++;
        return _index; 
    }
}