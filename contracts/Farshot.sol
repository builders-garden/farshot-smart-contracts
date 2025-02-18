// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/// @title Farshot
/// @notice Contract for handling random number generation using Chainlink VRF
contract Farshot is VRFConsumerBaseV2Plus {
    // Events
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event ShotWon(uint256 requestId, uint8 multiplier);

    // Structs
    struct RequestStatus {
        address player;
        bool fulfilled;      // whether the request has been successfully fulfilled
        bool exists;  
        uint8 multiplier;      // whether a requestId exists
        uint256[] randomWords;
    }

    // Constants
    uint256 public constant MULTIPLIER_1X = 68896293096203133191703691102907976132128423581023938760847514421746068357120;
    uint256 public constant MULTIPLIER_2X = 93212631836039542972396558723639535729588902696733014929917893241800849620992;
    uint256 public constant MULTIPLIER_3X = 105370801205957741434990815498044213360470772889937142925641107520656899047424;
    uint256 public constant MIN_VALUE = 0.001 ether;
    uint256 public constant MAX_VALUE = 0.01 ether;

    // VRF Configuration
    bytes32 public keyHash = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;

    // State Variables
    uint256 public s_subscriptionId;
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // Request Status Mapping
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    mapping(uint8 => uint256) public multipliers;
    /**
     * @dev Constructor
     * @param subscriptionId Chainlink VRF subscription ID
     * COORDINATOR: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B (SEPOLIA)
     */
    constructor(
        uint256 subscriptionId
    ) VRFConsumerBaseV2Plus(0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B) {
        s_subscriptionId = subscriptionId;
    }

    /**
     * @dev Requests random words from Chainlink VRF
     * @param enableNativePayment Set to true to enable payment in native tokens, false for LINK
     */
    function requestRandomWords(
        address player,
        bool enableNativePayment,
        uint8 multiplier
    ) external onlyOwner returns (uint256 requestId) {
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
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false,
            multiplier: multiplier
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    /**
     * @dev Callback function used by VRF Coordinator to return the random number
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        uint8 multiplier = s_requests[_requestId].multiplier;
        uint256 multiplierValue = multipliers[multiplier];

        if (_randomWords[0] >= multiplierValue) {
            // TODO: Send ETH to player
            emit ShotWon(_requestId, multiplier);
        }
        
        emit RequestFulfilled(_requestId, _randomWords);
    }

    /**
     * @dev Returns the status of a random word request
     */
    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }
}
