// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import {Gilt} from "./IGFStructs.sol";

interface IGiltVault { 

    function isVaulted(uint256 _giltVaultId) view external returns (bool _isVaulted);

    function getGilt(uint256 _giltVaultId) view external returns (Gilt memory _gilt);

    function vaultGilt(uint256 _giltId, address _giltContract) external returns (uint256 _giltVaultId);

    function releaseGilt(uint256 _giltVaultId) external returns (address _giltContract, uint256 _giltId);
}