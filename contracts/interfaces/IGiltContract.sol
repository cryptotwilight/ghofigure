// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import {ProtoGilt, Gilt} from "./IGFStructs.sol";

interface IGiltContract { 

    function getGiltIds() view external returns (uint256 [] memory _giltIds);

    function getGilt(uint256 _giltId) view external returns (Gilt memory _gilt);

    function isKnownGilt(uint256 _giltId) view external returns (bool _isKnownGilt);

    function mintGilt(ProtoGilt memory _pGilt) external returns (uint256 _giltId);

    function dissolveGilt(uint256 _giltId, address _fundsTo) external returns (address _erc20, uint256 _amount);

}