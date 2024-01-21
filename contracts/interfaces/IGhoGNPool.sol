// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import {GiltNote} from "./IGFStructs.sol";
import {Loan} from "./IGFStructs.sol";

interface IGhoGNPool { 

    function getAvailableGiltNoteIds() view external returns (int256 [] memory _gnIds);

    function getGiltNote(int256 _gnId) view external returns (GiltNote memory _note);

    function getCreditLimit(int256 _gnId) view external returns (uint256 _limit);

    function hasLoan(int256 _gnId) view external returns (bool _hasLoan);

    function getLoanIds() view external returns (uint256 [] memory _loanIds);

    function getLoan(uint256 _loanId) view external returns (Loan memory _loan);

    function borrowGho(int256 _gnId, uint256 _ghoAmount) external returns (uint256 _loanId);

    function repayGho(uint256 _loanId, uint256 _ghoAmount) external returns (int256 _gnId);

    function notifyGNArrival(GiltNote memory _gn) external returns (bool _acknowledged);
}