// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IFarshot {
    // Events
    event RequestSent(uint256 requestId, uint32 numWords, address player, uint8 multiplier);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords, uint256 payout, address player, bool win);
    event ShotWon(uint256 requestId, uint256 winAmount, address player);
    event VRFConfigUpdated(string configType, uint256 value);
    event ContractPaused();

    // Custom Errors
    error OnlyOwner();
    error RequestNotFound();
    error InvalidValue();
    error InvalidMultiplier();
    error InvalidReferralFeePercentage();
    error WithdrawTimeInvalid();
    error ContractIsPaused();
    // Structs
    struct RequestStatus {
        address player;
        uint256 value;
        bool fulfilled;     
        bool exists;  
        uint8 multiplier;      
        uint256[] randomWords;
    }

    // Structs
    struct Multiplier {
        uint256 numberToBeat;
        uint256 winMultiplier;
    }
}
