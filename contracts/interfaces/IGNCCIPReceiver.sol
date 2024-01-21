// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import {GiltNote} from "./IGFStructs.sol";

interface IGNCCIPReceiver { 

    function getAllRecievedGiltNoteIds() view external returns (int256 [] memory _gnIds);

    function getGNIds(address _owner) view external returns (int256 [] memory _gnIds);

    function getGN(int256 _giId) view external returns (GiltNote memory _gn);

    function lockGN(int256 _gnId) external returns (bool _locked);

    function unlockGN(int256 _gnId) external returns (bool _unlocked);

    function isLocked(int256 _gnId) view external returns (bool _isLocked);

}