// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "../interfaces/IGFVersion.sol";
import "../interfaces/IGFRegister.sol";
import "../interfaces/IGNCCIPSender.sol";
import "../interfaces/IGNCCIPRegister.sol";
import "../interfaces/IGiltContract.sol";
import "../interfaces/IGiltVault.sol";


import {Gilt, GiltNote} from "../interfaces/IGFStructs.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract GNCCIPSender is IGNCCIPSender, IGFVersion { 

    string constant name = "RESERVED_GILT_NOTE_CCIP_SENDER";
    uint256 constant version = 1; 

    string constant GN_CCIP_REGISTER_CA = "RESERVED_GILT_NOTE_CCIP_REGISTER"; 

    int256 constant LOCAL = -1; 

    string constant GILT_VAULT_CA = "RESERVED_GILT_VAULT";

    address immutable self; 
    uint256 chainId; 

    uint256 index; 

    uint256 [] sendIds; 
    mapping(uint256=>Send) sendRecordById; 

    IGFRegister register; 

    constructor(address _register, uint256 _chainId) {
        register = IGFRegister(_register);
        self = address(self);
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

    function getAllSendIds() view external returns (uint256 [] memory _sendIds){
        return sendIds; 
    }

    function getSendRecord(uint256 _sendId) view external returns (Send memory _send){
        return sendRecordById[_sendId];
    }
    

    function estimateSendFee(uint256 _destinationChainId, address _giltContract, uint256 _giltId, address _feeToken) view external returns (uint256 _feeEstimate) {
        IGiltContract giltContract_ = IGiltContract(_giltContract);
        Gilt memory gilt_ = giltContract_.getGilt(_giltId);
        GiltNote memory giltNote_ = createGiltNote(gilt_);

        IGNCCIPRegister ccipRegister_ = IGNCCIPRegister(register.getAddress(GN_CCIP_REGISTER_CA));
        CCIPDestination memory destination_ = ccipRegister_.getCCIPDestination(_destinationChainId);
        IRouterClient ccipClient_ = IRouterClient(destination_.router);
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage( destination_.receiver,  giltNote_, _feeToken);
        _feeEstimate = ccipClient_.getFee(destination_.chainSelector, evm2AnyMessage);

        return _feeEstimate; 
    }

    function sendGilt(uint256 _destinationChainId, address _giltContract, uint256 _giltId, address _feeToken) external returns (uint256 _sendId){
        IERC721 erc721_ = IERC721(_giltContract);
        require(erc721_.ownerOf(_giltId) == msg.sender, " direct Gilt owner only ");
        erc721_.transferFrom(msg.sender, self, _giltId);
        IGiltVault gVault_ = IGiltVault(register.getAddress(GILT_VAULT_CA));
        IGiltContract giltContract_ = IGiltContract(_giltContract);
        Gilt memory gilt_ = giltContract_.getGilt(_giltId);
        GiltNote memory giltNote_ = createGiltNote(gilt_);
        erc721_.approve(address(gVault_), _giltId);
        gVault_.vaultGilt(_giltId, _giltContract);

        _sendId = getIndex(); 
     
        IGNCCIPRegister ccipRegister_ = IGNCCIPRegister(register.getAddress(GN_CCIP_REGISTER_CA));
        CCIPDestination memory destination_ = ccipRegister_.getCCIPDestination(_destinationChainId);

        IRouterClient ccipClient_ = IRouterClient(destination_.router);
        Client.EVM2AnyMessage memory evm2AnyMessage_ = _buildCCIPMessage( destination_.receiver,  giltNote_, _feeToken);
        uint256 fees_ = ccipClient_.getFee(destination_.chainSelector, evm2AnyMessage_);
        IERC20 feeToken_ = IERC20(_feeToken);
        feeToken_.transferFrom(msg.sender, self, fees_);
        feeToken_.approve(destination_.router, fees_);
        
        sendRecordById[_sendId] = Send({
                                            id : _sendId,
                                            gilt : gilt_, 
                                            giltNote : giltNote_, 
                                            destination : destination_, 
                                            sendDate : block.timestamp, 
                                            ccipMessageId : ccipClient_.ccipSend(destination_.chainSelector, evm2AnyMessage_)
                                        });
        return _sendId; 
    }
    function _buildCCIPMessage(
        address _receiver,
        GiltNote memory _gn,
        address _feeTokenAddress
    ) internal pure returns (Client.EVM2AnyMessage memory) {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(_receiver), // ABI-encoded receiver address
                data: abi.encode(_gn), // ABI-encoded string
                tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array aas no tokens are transferred
                extraArgs: Client._argsToBytes(
                    // Additional arguments, setting gas limit
                    Client.EVMExtraArgsV1({gasLimit: 400_000})
                ),
                // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
                feeToken: _feeTokenAddress
            });
    }
    //=================================== INTERNAL ============================================================================

    function getIndex() internal returns (uint256 _index) {
        _index = index++; 
        return _index; 
    }

    function createGiltNote(Gilt memory gilt_) view internal returns (GiltNote memory _gn) {
        return GiltNote({
                            id : gilt_.id, 
                            originChainId : chainId, 
                            amount : gilt_.amount,  
                            erc20  : gilt_.erc20, 
                            owner : msg.sender, 
                            createDate : block.timestamp,  
                            giltContract : gilt_.giltContract, 
                            giltVault : gilt_.giltVault, 
                            localId : LOCAL 
                        });
    }

}