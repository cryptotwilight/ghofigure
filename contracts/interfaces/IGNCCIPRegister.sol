// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import {CCIPDestination, CCIPOrigin} from "../interfaces/IGFStructs.sol";

interface IGNCCIPRegister { 

    function getSupportedDestinationChainIds() view external returns (uint256 [] memory _chainIds);

    function getCCIPDestination(uint256 _destinationChainId) view external returns (CCIPDestination memory _destination);

    function isAllowedOrigin(CCIPOrigin memory _origin) view external returns (bool isAllowed);

}