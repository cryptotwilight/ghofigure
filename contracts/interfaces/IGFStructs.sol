// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

struct ProtoGilt {
    uint256 amount;
    address erc20; 
    address owner; 
}

struct Gilt { 
    uint256 id; 
    uint256 amount; 
    address erc20; 
    address giltVault; 
    address giltContract; 
}

struct GiltNote { 
    uint256 id; 
    uint256 originChainId; 
    uint256 amount; 
    address erc20; 
    uint256 decimals; 
    string symbol; 
    address owner; 
    uint256 createDate; 
    address giltContract; 
    address giltVault; 
    int256 localId; 
}

enum LoanStatus {OPEN, SETTLED}

struct Loan {
    uint256 amount; 
    int256 gnId; 
    address owner; 
    uint256 createDate; 
    uint256 lastPaymentDate; 
    int256 balance; 
    uint256 totalPaid;
    LoanStatus status; 
}

struct Send {
    uint256 id; 
    Gilt gilt; 
    GiltNote giltNote; 
    CCIPDestination destination; 
    uint256 sendDate; 
    bytes32 ccipMessageId; 
}

struct CCIPDestination { 
    string name; 
    uint64 chainSelector; 
    address router; 
    uint256 chainId; 
    address receiver; 
  
}

struct CCIPOrigin { 
    uint256 chainId; 
    address source;
    uint64 chainSelector;  
}