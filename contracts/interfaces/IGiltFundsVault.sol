// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;


interface IGiltFundsVault { 

    function getGiltId() view external returns (uint256 _giltId); 

    function getGiltContract() view external returns (address _giltContract); 

    function commitFunds(address _token, uint256 _amount) external returns (bool _committed);

    function releaseFunds() external returns (bool _released);

}