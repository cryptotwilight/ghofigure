// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import {Send} from "./IGFStructs.sol";

interface IGNCCIPSender {

    function getChainId() view external returns (uint256 _chainId);

    function getAllSendIds() view external returns (uint256 [] memory _sendIds);

    function getSendRecord(uint256 _sendId) view external returns (Send memory _send);
    
    function sendGilt(uint256 _destinationChainId, address _giltContract, uint256 _giltId, address _feeToken) external returns (uint256 _sendId);

}