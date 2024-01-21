// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;


interface IGiltFundsVaultFactory { 

    function getGiltFundsVault(uint256 _giltId, address _giltContract) external returns (address _vault);

}