// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "../interfaces/IGFVersion.sol";
import "../interfaces/IGFRegister.sol";
import "../interfaces/IGhoGNPool.sol";
import "../interfaces/IGNCCIPReceiver.sol";
import {Loan, LoanStatus} from "../interfaces/IGFStructs.sol";
import "../interfaces/IGFPriceFeed.sol";

import "https://github.com/aave/gho-core/blob/main/src/contracts/gho/interfaces/IGhoFacilitator.sol"; 
import "https://github.com/aave/gho-core/blob/main/src/contracts/gho/interfaces/IGhoToken.sol";

import "@chainlink/contracts/src/v0.8/Denominations.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";


contract GhoGNPool is IGhoGNPool, IGhoFacilitator, IGFVersion { 

  modifier receiverOnly() {
    require(msg.sender == register.getAddress(GN_RECIEVER_CA), " Gilt Note Receiver Only");
    _;
  }

  modifier adminOnly() {
    require(msg.sender == register.getAddress(GN_ADMIN_CA), " Gho Figure Admin Only");
    _;
  }

  string constant name = "RESERVED_GHO_GILT_NOTE_POOL";
  uint256 constant version = 5; 

  uint256 risk_factor = 80; // lend upto 80% of collateral value

  string constant GN_ADMIN_CA = "RESERVED_GHO_FIGURE_ADMIN";
  string constant GN_RECIEVER_CA = "RESERVED_GILT_NOTE_CCIP_RECEIVER"; 
  string constant GHO_TREASURY_CA = "RESERVED_GHO_TREASURY";
  string constant GHO_TOKEN_CA = "RESERVED_GHO_TOKEN";
  string constant GF_PRICE_FEED_CA = "RESERVED_GHO_FIGURE_PRICE_FEED";

  address immutable self; 

  uint256 annualisedInterest = 5; 
  uint256 interestPerSecond;
  uint256 creditFactor = 80;
  uint256 serviceFees; 


  uint256 [] loanIds; 
  mapping(uint256=>Loan) loanById; 
  mapping(address=>uint256[]) loanIdsByAddress; 
  mapping(int256=>bool) hasLoanByGNId; 

  IGFRegister register; 

  constructor(address _register) {
      register = IGFRegister(_register);
      self = address(self);
      assertConfigInternal(GN_ADMIN_CA);
      assertConfigInternal(GN_RECIEVER_CA);
      assertConfigInternal(GHO_TREASURY_CA);
      assertConfigInternal(GHO_TOKEN_CA);
      assertConfigInternal(GF_PRICE_FEED_CA);
  }

  /**
   * @notice Distribute fees to the GhoTreasury
   */
  function distributeFeesToTreasury() external {
     IERC20 erc20_ = IERC20(register.getAddress(GHO_TOKEN_CA));
    uint256 balance = erc20_.balanceOf(self);
    erc20_.transfer(register.getAddress(GHO_TREASURY_CA), balance);
    emit FeesDistributedToTreasury(register.getAddress(GHO_TREASURY_CA), register.getAddress(GHO_TOKEN_CA), balance);
  }

  /**
   * @notice Updates the address of the Gho Treasury
   * @dev WARNING: The GhoTreasury is where revenue fees are sent to. Update carefully
   * @param newGhoTreasury The address of the GhoTreasury
   */
  function updateGhoTreasury(address newGhoTreasury) external{

  }

  /**
   * @notice Returns the address of the Gho Treasury
   * @return The address of the GhoTreasury contract
   */
  function getGhoTreasury() external view returns (address){
    return register.getAddress(GHO_TREASURY_CA);
  }

  function getName() pure external returns (string memory _name) {
    return name; 
  }

  function getVersion() pure external returns (uint256 _version) {
    return version; 
  }

  function getAllLoansIds() view external returns (uint256 [] memory _loanIds) {
    return loanIds; 
  }

  function getServiceFees() view external returns (uint256 _serviceFee) {
    return serviceFees;
  }

  function getAvailableGiltNoteIds() view external returns (int256 [] memory _gnIds){
      int256 [] memory rGnIds_ = IGNCCIPReceiver(register.getAddress(GN_RECIEVER_CA)).getGNIds(msg.sender);
      uint256 [] memory lGnIds_ = loanIdsByAddress[msg.sender];

      uint256 length_ = rGnIds_.length - lGnIds_.length; 

      _gnIds = new int256[](length_);
      uint256 y_ = 0; 
      for(uint256 x = 0; x < rGnIds_.length; x++) { 
        if(!hasLoanByGNId[rGnIds_[x]]){
           _gnIds[y_] = rGnIds_[x]; 
           y_++;
        } 
      }
      return _gnIds; 
  }

  function getGiltNote(int256 _gnId) view external returns (GiltNote memory _note){
    return IGNCCIPReceiver(register.getAddress(GN_RECIEVER_CA)).getGN(_gnId);
  }

  function getCreditLimit(int256 _gnId) view external returns (uint256 _limit){
      require(!hasLoanByGNId[_gnId], "Gilt Note already has loan");
      return calculateCreditLimitInternal(IGNCCIPReceiver(register.getAddress(GN_RECIEVER_CA)).getGN(_gnId));
  }

  function hasLoan(int256 _gnId) view external returns (bool _hasLoan) {
    return hasLoanByGNId[_gnId];
  }

  function getLoanIds() view external returns (uint256 [] memory _loanIds){
      return loanIdsByAddress[msg.sender];
  }

  function getLoan(uint256 _loanId) view external returns (Loan memory _loan){
    return loanById[_loanId];
  }

  function borrowGho(int256 _gnId, uint256 _ghoAmount) external returns (uint256 _loanId){
    IGNCCIPReceiver receiver_ = IGNCCIPReceiver(register.getAddress(GN_RECIEVER_CA)); 
    GiltNote memory gn_ = receiver_.getGN(_gnId);
    require(gn_.owner == msg.sender, " Gilt Note Owner only ");
    require(!receiver_.isLocked(_gnId), " Gilt Note Locked ");
    receiver_.lockGN(_gnId);

    uint256 creditLimit = calculateCreditLimitInternal(gn_);
    
    (bool ok_, uint256 res_) = Math.tryDiv(risk_factor, 100);
    require(ok_, " failed to calculate risk factor" );
    (bool ok1_, uint256 borrowLimit_) = Math.tryMul(creditLimit, res_);

    require(ok1_, " failed to calculate borrowLimit ");

    require(borrowLimit_ >= _ghoAmount, " insufficient borrow limit ");

    hasLoanByGNId[_gnId] = true;
    _loanId = getIndex(); 
    loanById[_loanId] = Loan({
                                amount : _ghoAmount,  
                                gnId : _gnId, 
                                owner : msg.sender, 
                                createDate : block.timestamp, 
                                lastPaymentDate : block.timestamp,
                                totalPaid : 0,
                                balance  : int256(_ghoAmount)*-1,
                                status : LoanStatus.OPEN 
                              });
    IGhoToken gho_ = IGhoToken(register.getAddress(GHO_TOKEN_CA));
    (uint256 capacity_, uint256 level_) = gho_.getFacilitatorBucket(self);
    require((capacity_ - level_) > _ghoAmount, " insufficient lending capacity remaining ");
    gho_.mint(msg.sender, _ghoAmount);
    return _loanId; 
  }

  function getCurrentBalance(uint256 _loanId) view external returns (int256 _balance) {
    return calculateBalance(_loanId);
  }

  function repayGho(uint256 _loanId, uint256 _ghoAmount) external returns (int256 _gnId){
    require(loanById[_loanId].status == LoanStatus.OPEN," loan already settled ");
    IERC20 erc20_ = IERC20(register.getAddress(GHO_TOKEN_CA));
    erc20_.transferFrom(msg.sender, self, _ghoAmount);
    IGhoToken gho_ = IGhoToken(register.getAddress(GHO_TOKEN_CA));
    int256 balance_  = calculateBalance(_loanId);
    int256 trialBalance_ = balance_ + int256(_ghoAmount); 

    if(trialBalance_ > 0){
      loanById[_loanId].balance = 0;
      loanById[_loanId].totalPaid += uint256(balance_ * -1);  
      erc20_.transfer(msg.sender, uint256(trialBalance_)); // change
    }
    else {
      loanById[_loanId].balance = trialBalance_;
      loanById[_loanId].totalPaid += _ghoAmount; 
    }

    loanById[_loanId].lastPaymentDate = block.timestamp; 
     
    if(loanById[_loanId].balance == 0) {
      loanById[_loanId].status = LoanStatus.SETTLED; 
      IGNCCIPReceiver receiver_ = IGNCCIPReceiver(register.getAddress(GN_RECIEVER_CA)); 
      receiver_.unlockGN(loanById[_loanId].gnId);
      gho_.burn(loanById[_loanId].amount);
      serviceFees += loanById[_loanId].totalPaid - loanById[_loanId].amount; // only charge fees once loan is settled
      hasLoanByGNId[_gnId] = false; 
    }
    return loanById[_loanId].gnId; 
  }


  function notifyGNArrival(GiltNote memory _gn) external receiverOnly returns (bool _acknowledged) {
    return true; 
  } 

  function getCreditFactor() view external returns (uint256 _creditFactor) {
    return creditFactor; 
  }

  function setCreditFactor(uint256 _creditFactor) external adminOnly returns (uint256 _setFactor) {
      creditFactor = _creditFactor; 
      return creditFactor;
  }

  function getAnnualisedInterest() view external adminOnly returns (uint256 _interest) {
    return annualisedInterest; 
  }

  function checkCreditLimit(GiltNote memory _gn) view external adminOnly returns (uint256 _limit) {
     return calculateCreditLimitInternal(_gn);
  }

  function setInterestPerSecond(uint256 totalAnnualisedInterest) external adminOnly returns (uint256 _interestPerSecond) {
    annualisedInterest = totalAnnualisedInterest; 
    (bool ok_, uint256 nominator_) = Math.tryMul(annualisedInterest, 1e18); 
    require(ok_, "failed to calculate nominator");

    uint256 secondsPerYear = (365*24*60*60);
    (bool k_, uint256 nominatorPerSecond_) = Math.tryDiv(nominator_, secondsPerYear);

    require(k_, "failed to calculate nominator per second");
    (bool ok1_, uint256 percentagePerSecond_) = Math.tryDiv(nominatorPerSecond_, 100); 

    require(ok1_, "failed to interest per second");
    interestPerSecond = percentagePerSecond_;

    return percentagePerSecond_; 
  }


  //======================================== INTERNAL =======================================================


  function assertConfigInternal(string memory _configurationAddressName) view internal returns ( bool ) {
    require(register.isSet(_configurationAddressName), string.concat(" missing configuration address :: ", _configurationAddressName)); 
    return true;
  }

  function calculateBalance(uint256 _loanId) view internal returns (int256 _balance) {
      Loan memory loan_ = loanById[_loanId]; 

      uint256 duration_ = block.timestamp - loan_.lastPaymentDate; 
      (bool ok_,  uint256 balance_) = Math.tryDiv(uint256((loan_.balance *-1) * int256(interestPerSecond) * int256(duration_)), 1e18); 
      require(ok_, " failed to calculate balance ");
      _balance = int256(balance_) * -1;
      return _balance ;
  }

  function calculateCreditLimitInternal(GiltNote memory _gn) view internal returns (uint256 _limit) {
      IGFPriceFeed feed_ = IGFPriceFeed(register.getAddress(GF_PRICE_FEED_CA));
     
      uint256 price_ = feed_.getPrice(_gn.symbol, "USD");
      (bool ok_, uint256 usdValue_) = Math.tryMul(uint256(price_), _gn.amount);
      require(ok_, " failed to calculate USD value ");
      (bool k_, uint256 nominator_) = Math.tryMul(creditFactor, usdValue_);
      require(k_, " failed to calculate nominator ");
      (bool ok1_, uint256 creditLimit_) = Math.tryDiv(nominator_, 100);

      require(ok1_, "failed to calculate credit limit ");
      (bool k1_, uint256 normalizedLimit_) = Math.tryDiv(creditLimit_, 1e18);
      require(k1_, " failed to normalize limit ");

      return normalizedLimit_; 
  } 

  uint256 index = 0; 

  function getIndex() internal returns (uint256 _index) {
      _index = index++;
      return _index; 
  }

}