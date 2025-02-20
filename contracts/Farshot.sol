// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "hardhat/console.sol"; // Remove this import in production
import {IFarshot} from "./IFarshot.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Farshot
/// @notice Contract for handling a chance-based game using Chainlink VRF for randomness.
contract Farshot is VRFConsumerBaseV2Plus, IFarshot, Pausable, ReentrancyGuard {
    // Custom error for invalid random words length.
    error InvalidRandomWords();

    // Constants
    uint256 public constant MIN_VALUE = 0.00001 ether; //TODO: Change
    uint256 public constant MAX_VALUE = 1 ether; //TODO: Change
    uint256 public constant MAX_BET_PERCENT = 100; // 1% = 100 since we'll divide by 10000
    uint256 public constant NUMBER_TO_BEAT_1 = 68896293096203130000000000000000000000000000000000000000000000000000000000000;
    uint256 public constant NUMBER_TO_BEAT_2 = 93212631836039540000000000000000000000000000000000000000000000000000000000000;
    uint256 public constant NUMBER_TO_BEAT_3 = 105370801205957740000000000000000000000000000000000000000000000000000000000000;
    uint256 public constant NUMBER_TO_BEAT_4 = 1; //TODO: Change
    uint256 public constant NUMBER_TO_BEAT_5 = 1; //TODO: Change

    // Owner
    address public admin;
    // Although OZ's Pausable provides a paused() flag, we also record pauseTime for withdrawal logic.
    uint256 public pauseTime;

    // VRF Configuration
    bytes32 public keyHash; // BASE 30 gwei hash lane.
    uint32 public callbackGasLimit;
    uint16 public requestConfirmations;
    uint32 public numWords;

    // State Variables
    uint256 public s_subscriptionId;
    uint256 public lastRequestId;

    // Mappings
    mapping(uint256 => RequestStatus) public s_requests;
    mapping(uint8 => Multiplier) public multipliers;

    // Modifiers
    modifier onlyAdmin() {
        if (msg.sender != admin) revert OnlyOwner();
        _;
    }

    /**
     * @notice Constructor initializes the contract with VRF parameters and default multiplier settings.
     * @param _admin The address of the admin.
     * @param _keyHash The key hash for VRF requests.
     * @param _callbackGasLimit The gas limit for the VRF callback.
     * @param _requestConfirmations The number of confirmations for the VRF request.
     * @param _numWords The number of random words to request.
     */
    constructor(
        address _admin,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        admin = _admin;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;

        // Initialize default multiplier settings.
        multipliers[1] = Multiplier({ numberToBeat: NUMBER_TO_BEAT_1, winMultiplier: 2 });
        multipliers[2] = Multiplier({ numberToBeat: NUMBER_TO_BEAT_2, winMultiplier: 3 });
        multipliers[3] = Multiplier({ numberToBeat: NUMBER_TO_BEAT_3, winMultiplier: 4 });
    }

    /**
     * @notice Initializes the VRF subscription ID
     * @param _subscriptionId The subscription ID to use for VRF requests
     */
    function initialize(uint256 _subscriptionId) external onlyAdmin {
        if (s_subscriptionId != 0) revert("Already initialized");
        s_subscriptionId = _subscriptionId;
        emit VRFConfigUpdated("subscriptionId", _subscriptionId);
    }

    /**
     * @notice Returns the status of a VRF request.
     * @param _requestId The ID of the request.
     * @return fulfilled Boolean indicating if the request was fulfilled.
     * @return randomWords The array of random words received.
     */
    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        if (!s_requests[_requestId].exists) revert RequestNotFound();
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    /**
     * @notice Updates the VRF subscription ID.
     * @param _subscriptionId The new subscription ID.
     */
    function setSubscriptionId(uint256 _subscriptionId) external onlyAdmin {
        s_subscriptionId = _subscriptionId;
        emit VRFConfigUpdated("subscriptionId", _subscriptionId);
    }

    /**
     * @notice Updates the key hash used for VRF requests.
     * @param _keyHash The new key hash.
     */
    function setKeyHash(bytes32 _keyHash) external onlyAdmin {
        keyHash = _keyHash;
        emit VRFConfigUpdated("keyHash", uint256(_keyHash));
    }

    /**
     * @notice Updates the callback gas limit for VRF requests.
     * @param _callbackGasLimit The new gas limit.
     */
    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyAdmin {
        callbackGasLimit = _callbackGasLimit;
        emit VRFConfigUpdated("callbackGasLimit", _callbackGasLimit);
    }

    /**
     * @notice Updates the number of confirmations required for VRF requests.
     * @param _requestConfirmations The new number of confirmations.
     */
    function setRequestConfirmations(uint16 _requestConfirmations) external onlyAdmin {
        requestConfirmations = _requestConfirmations;
        emit VRFConfigUpdated("requestConfirmations", _requestConfirmations);
    }

    /**
     * @notice Pauses or unpauses the contract.
     * @param pause True to pause the contract, false to unpause.
     * @dev When pausing, the current timestamp is recorded for withdrawal timing.
     */
    function setPause(bool pause) external onlyAdmin {
        if (pause) {
            _pause(); // Call OZ's internal pause
            pauseTime = block.timestamp;
        } else {
            _unpause(); // Call OZ's internal unpause
            pauseTime = 0;
        }
        emit ContractPaused();
    }

    /**
     * @notice Requests random words from Chainlink VRF for a player's game bet.
     * @param player The address of the player.
     * @param enableNativePayment True if native payment is enabled.
     * @param multiplier The selected multiplier (allowed values: 1, 2, or 3).
     * @return requestId The unique identifier of the VRF request.
     */
    function requestRandomWords(
        address player,
        bool enableNativePayment,
        uint8 multiplier
    ) external payable whenNotPaused nonReentrant returns (uint256 requestId) {
        // Validate bet value
        if (msg.value < MIN_VALUE || msg.value > MAX_VALUE) {
            revert InvalidValue();
        }

        // Determine the contract balance before the current deposit
        uint256 currentBalance = address(this).balance - msg.value;
        if (currentBalance == 0 || msg.value > (currentBalance * MAX_BET_PERCENT) / 10000) {
            revert InvalidValue();
        }

        // Validate the multiplier selection
        if (multiplier != 1 && multiplier != 2 && multiplier != 3) {
            revert InvalidMultiplier();
        }

        // Request random words from the VRF coordinator
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: enableNativePayment
                    })
                )
            })
        );

        // Record the request details
        s_requests[requestId] = RequestStatus({
            player: player,
            value: msg.value,
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false,
            multiplier: multiplier
        });

        lastRequestId = requestId;
        emit RequestSent(requestId, numWords, player, multiplier);
        return requestId;
    }

    /**
     * @notice Callback function used by the VRF coordinator to provide randomness.
     * @param _requestId The ID of the VRF request.
     * @param _randomWords The array of random words provided.
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override nonReentrant {
        if (!s_requests[_requestId].exists) revert RequestNotFound();
        if (_randomWords.length != numWords) revert InvalidRandomWords();

        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        uint8 multiplier = s_requests[_requestId].multiplier;
        uint256 numberToBeat = multipliers[multiplier].numberToBeat;
        uint256 payout;

        // Check if the random word meets the win condition
        if (_randomWords[0] >= numberToBeat) {
            uint256 winAmount = s_requests[_requestId].value * multipliers[multiplier].winMultiplier;
            address player = s_requests[_requestId].player;
            
            
            if (address(this).balance == 0) {
                // If contract has no balance, no payout possible
                payout = 0;
            } else if (winAmount > address(this).balance) {
                // If can't pay full amount, return the original bet or whatever is left in the contract
                payout = address(this).balance < s_requests[_requestId].value ? 
                    address(this).balance : s_requests[_requestId].value;
            } else {
                payout = winAmount;
            }
            
            if (payout > 0) {
                (bool success, ) = player.call{value: payout}("");
                require(success, "Transfer failed");
            }
        }
        emit RequestFulfilled(_requestId, _randomWords, payout, s_requests[_requestId].player, _randomWords[0] >= numberToBeat);
    }

    /**
     * @notice Allows the admin to withdraw the contract's balance.
     * @dev Withdrawals are permitted only after 24 hours have passed since the contract was paused.
     */
    function withdraw() external onlyAdmin nonReentrant {
        if (block.timestamp < pauseTime + 24 hours) {
            revert WithdrawTimeInvalid();
        }
        (bool success, ) = admin.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    /// @notice Allows the contract to receive ETH
    receive() external payable {}
}
