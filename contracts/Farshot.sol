// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "hardhat/console.sol";
import {IFarshot} from "./IFarshot.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/// @title Farshot
/// @notice Contract for handling random number generation using Chainlink VRF
contract Farshot is VRFConsumerBaseV2Plus, IFarshot {

    // Constants
    uint256 public constant MIN_VALUE = 0.001 ether;
    uint256 public constant MAX_VALUE = 0.01 ether;

    // Owner
    address public admin;

    // VRF Configuration
    bytes32 public keyHash; // BASE 30 gwei hash lane
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
     * @notice Constructor initializes the contract with VRF coordinator and subscription ID
     * @param _subscriptionId Chainlink VRF subscription ID for random number generation
     * @dev VRF Coordinator address: 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634 (BASE)
     */
    constructor(
        address _admin,
        uint256 _subscriptionId,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords
    ) VRFConsumerBaseV2Plus(0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634) {
        admin = _admin;
        s_subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;
    }

    /**
     * @notice Returns the status of a random word request
     * @param _requestId The ID of the request to check
     * @return fulfilled Boolean indicating if the request was fulfilled
     * @return randomWords Array of random values if the request was fulfilled
     */
    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        if (!s_requests[_requestId].exists) revert RequestNotFound();
        
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    /**
     * @notice Updates the VRF subscription ID
     * @param _subscriptionId New subscription ID
     */
    function setSubscriptionId(uint256 _subscriptionId) external onlyAdmin {
        s_subscriptionId = _subscriptionId;
        emit VRFConfigUpdated("subscriptionId", _subscriptionId);
    }

    /**
     * @notice Updates the key hash for VRF requests
     * @param _keyHash New key hash value
     */
    function setKeyHash(bytes32 _keyHash) external onlyAdmin {
        keyHash = _keyHash;
        emit VRFConfigUpdated("keyHash", uint256(_keyHash));
    }

    /**
     * @notice Updates the callback gas limit for VRF requests
     * @param _callbackGasLimit New gas limit value
     */
    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyAdmin {
        callbackGasLimit = _callbackGasLimit;
        emit VRFConfigUpdated("callbackGasLimit", _callbackGasLimit);
    }

    /**
     * @notice Updates the number of confirmations required for VRF requests
     * @param _requestConfirmations New confirmations value
     */
    function setRequestConfirmations(uint16 _requestConfirmations) external onlyAdmin {
        requestConfirmations = _requestConfirmations;
        emit VRFConfigUpdated("requestConfirmations", _requestConfirmations);
    }

    /**
     * @notice Updates the number of random words to request
     * @param _numWords New number of words value
     */
    function setNumWords(uint32 _numWords) external onlyAdmin {
        numWords = _numWords;
        emit VRFConfigUpdated("numWords", _numWords);
    }

    /**
     * @notice Requests random words from Chainlink VRF for the game
     * @param player Address of the player making the request
     * @param enableNativePayment True to enable payment in native tokens, false for LINK
     * @param multiplier Selected multiplier (1, 2, or 3)
     * @return requestId Unique identifier for the VRF request
     */
    function requestRandomWords(
        address player,
        bool enableNativePayment,
        uint8 multiplier
    ) external payable returns (uint256 requestId) {
        if (msg.value < MIN_VALUE || msg.value > MAX_VALUE) {
            revert InvalidValue();
        }

        if (multiplier != 1 && multiplier != 2 && multiplier != 3) {
            revert InvalidMultiplier();
        }

        // Will revert if subscription is not set and funded.
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
     * @notice Callback function used by VRF Coordinator to return the random number
     * @param _requestId The ID of the request
     * @param _randomWords Array of random values generated by Chainlink VRF
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        if (!s_requests[_requestId].exists) revert RequestNotFound();

        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        uint8 multiplier = s_requests[_requestId].multiplier;
        uint256 numberToBeat = multipliers[multiplier].numberToBeat;

        if (_randomWords[0] >= numberToBeat) {
            uint256 winAmount = s_requests[_requestId].value * multipliers[multiplier].winMultiplier;
            address player = s_requests[_requestId].player;
            payable(player).transfer(winAmount);
            
            emit ShotWon(_requestId, winAmount, player);
        }
        
        emit RequestFulfilled(_requestId, _randomWords);
    }

}
