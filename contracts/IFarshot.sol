// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title IFarshot Interface
/// @notice Interface for the Farshot contract, defining core functionality for a chance-based game
/// @dev Implements events, errors, and data structures for the Farshot game system
interface IFarshot {
    /// @notice Emitted when a new random number request is sent to Chainlink VRF
    /// @param requestId The unique identifier for the VRF request
    /// @param numWords The number of random words requested
    /// @param player The address of the player making the request
    /// @param multiplier The selected multiplier level (1-5)
    event RequestSent(uint256 requestId, uint32 numWords, address player, uint8 multiplier);

    /// @notice Emitted when a VRF request is fulfilled and the game result is determined
    /// @param requestId The ID of the fulfilled request
    /// @param randomWords The array of random words received from VRF
    /// @param payout The amount paid to the player (0 if lost)
    /// @param player The address of the player
    /// @param win Whether the player won (true) or lost (false)
    event RequestFulfilled(uint256 requestId, uint256[] randomWords, uint256 payout, address player, bool win);

    /// @notice Emitted when a player wins a shot
    /// @param requestId The ID of the winning request
    /// @param winAmount The amount won by the player
    /// @param player The address of the winning player
    event ShotWon(uint256 requestId, uint256 winAmount, address player);

    /// @notice Emitted when VRF configuration parameters are updated
    /// @param configType The type of configuration parameter that was updated
    /// @param value The new value for the configuration parameter
    event VRFConfigUpdated(string configType, uint256 value);

    /// @notice Emitted when the contract's pause status changes
    event ContractPaused();

    /// @notice Error thrown when a non-owner attempts to perform an admin-only action
    error OnlyOwner();

    /// @notice Error thrown when attempting to access a non-existent VRF request
    error RequestNotFound();

    /// @notice Error thrown when an invalid bet amount is provided
    error InvalidValue();

    /// @notice Error thrown when an invalid multiplier is selected
    error InvalidMultiplier();

    /// @notice Error thrown when an invalid referral fee percentage is set
    error InvalidReferralFeePercentage();

    /// @notice Error thrown when attempting to withdraw funds before the required time has passed
    error WithdrawTimeInvalid();

    /// @notice Error thrown when attempting to perform an action while the contract is paused
    error ContractIsPaused();

    /// @notice Error thrown when VRF returns incorrect number of random words
    error InvalidRandomWords();

    /// @notice Error thrown when an invalid admin address is provided
    error InvalidAdminAddress();

    /// @notice Structure containing the status and details of a VRF request
    /// @param player The address of the player who made the request
    /// @param value The amount of ETH bet by the player
    /// @param fulfilled Whether the VRF request has been fulfilled
    /// @param exists Whether the request exists in the system
    /// @param multiplier The selected multiplier level for this request
    /// @param randomWords The array of random words received from VRF (empty until fulfilled)
    struct RequestStatus {
        address player;
        uint256 value;
        bool fulfilled;     
        bool exists;  
        uint8 multiplier;      
        uint256[] randomWords;
    }

    /// @notice Structure defining the configuration for each multiplier level
    /// @param numberToBeat The threshold number that must be exceeded to win
    /// @param winMultiplier The multiplier applied to the bet amount on winning (in basis points)
    struct Multiplier {
        uint256 numberToBeat;
        uint256 winMultiplier;
    }
}
