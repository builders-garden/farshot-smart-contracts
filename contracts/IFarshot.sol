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


/*

// Initialize multipliers
        multipliers[1] = Multiplier({
            numberToBeat: 0x9b1ca4169f1f35c1efcb7656b85743c4d63a06e856c914ae5642fb690b628f2,
            winMultiplier: 1
        });
        multipliers[2] = Multiplier({
            numberToBeat: 0xb4a7ef927fb2e490f23c14b31f23b4f5f4d81f1a9c1f35c1efcb7656b85743c4,
            winMultiplier: 15 // 1.5x (we'll divide by 10 in the payout calculation)
        });
        multipliers[3] = Multiplier({
            numberToBeat: 0xce95a4169f1f35c1efcb7656b85743c4d63a06e856c914ae5642fb690b628f2d,
            winMultiplier: 2
        });
        multipliers[4] = Multiplier({
            numberToBeat: 0xdcb2e490f23c14b31f23b4f5f4d81f1a9c1f35c1efcb7656b85743c4d63a06e8,
            winMultiplier: 25 // 2.5x (we'll divide by 10 in the payout calculation)
        });
        multipliers[5] = Multiplier({
            numberToBeat: 0xe85c914ae5642fb690b628f2d63a06e856c914ae5642fb690b628f2d63a06e85,
            winMultiplier: 3
        });

*/