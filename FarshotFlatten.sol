// Sources flattened with hardhat v2.22.18 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @chainlink/contracts/src/v0.8/shared/interfaces/IOwnable.sol@v1.3.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnable {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}


// File @chainlink/contracts/src/v0.8/shared/access/ConfirmedOwnerWithProposal.sol@v1.3.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwnerWithProposal is IOwnable {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    // solhint-disable-next-line gas-custom-errors
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /// @notice Allows an owner to begin transferring ownership to a new address.
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /// @notice Allows an ownership transfer to be completed by the recipient.
  function acceptOwnership() external override {
    // solhint-disable-next-line gas-custom-errors
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /// @notice Get the current owner
  function owner() public view override returns (address) {
    return s_owner;
  }

  /// @notice validate, transfer ownership, and emit relevant events
  function _transferOwnership(address to) private {
    // solhint-disable-next-line gas-custom-errors
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /// @notice validate access
  function _validateOwnership() internal view {
    // solhint-disable-next-line gas-custom-errors
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /// @notice Reverts if called by anyone other than the contract owner.
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}


// File @chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol@v1.3.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}


// File @chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFSubscriptionV2Plus.sol@v1.3.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

/// @notice The IVRFSubscriptionV2Plus interface defines the subscription
/// @notice related methods implemented by the V2Plus coordinator.
interface IVRFSubscriptionV2Plus {
  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint256 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint256 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint256 subId, address to) external;

  /**
   * @notice Accept subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint256 subId) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint256 subId, address newOwner) external;

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription with LINK, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   * @dev Note to fund the subscription with Native, use fundSubscriptionWithNative. Be sure
   * @dev  to send Native with the call, for example:
   * @dev COORDINATOR.fundSubscriptionWithNative{value: amount}(subId);
   */
  function createSubscription() external returns (uint256 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return nativeBalance - native balance of the subscription in wei.
   * @return reqCount - Requests count of subscription.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(
    uint256 subId
  )
    external
    view
    returns (uint96 balance, uint96 nativeBalance, uint64 reqCount, address owner, address[] memory consumers);

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint256 subId) external view returns (bool);

  /**
   * @notice Paginate through all active VRF subscriptions.
   * @param startIndex index of the subscription to start from
   * @param maxCount maximum number of subscriptions to return, 0 to return all
   * @dev the order of IDs in the list is **not guaranteed**, therefore, if making successive calls, one
   * @dev should consider keeping the blockheight constant to ensure a holistic picture of the contract state
   */
  function getActiveSubscriptionIds(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  /**
   * @notice Fund a subscription with native.
   * @param subId - ID of the subscription
   * @notice This method expects msg.value to be greater than or equal to 0.
   */
  function fundSubscriptionWithNative(uint256 subId) external payable;
}


// File @chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol@v1.3.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.4;

// End consumer library.
library VRFV2PlusClient {
  // extraArgs will evolve to support new features
  bytes4 public constant EXTRA_ARGS_V1_TAG = bytes4(keccak256("VRF ExtraArgsV1"));
  struct ExtraArgsV1 {
    bool nativePayment;
  }

  struct RandomWordsRequest {
    bytes32 keyHash;
    uint256 subId;
    uint16 requestConfirmations;
    uint32 callbackGasLimit;
    uint32 numWords;
    bytes extraArgs;
  }

  function _argsToBytes(ExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
    return abi.encodeWithSelector(EXTRA_ARGS_V1_TAG, extraArgs);
  }
}


// File @chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol@v1.3.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;


// Interface that enables consumers of VRFCoordinatorV2Plus to be future-proof for upgrades
// This interface is supported by subsequent versions of VRFCoordinatorV2Plus
interface IVRFCoordinatorV2Plus is IVRFSubscriptionV2Plus {
  /**
   * @notice Request a set of random words.
   * @param req - a struct containing following fields for randomness request:
   * keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * requestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * extraArgs - abi-encoded extra args
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(VRFV2PlusClient.RandomWordsRequest calldata req) external returns (uint256 requestId);
}


// File @chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFMigratableConsumerV2Plus.sol@v1.3.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.0;

/// @notice The IVRFMigratableConsumerV2Plus interface defines the
/// @notice method required to be implemented by all V2Plus consumers.
/// @dev This interface is designed to be used in VRFConsumerBaseV2Plus.
interface IVRFMigratableConsumerV2Plus {
  event CoordinatorSet(address vrfCoordinator);

  /// @notice Sets the VRF Coordinator address
  /// @notice This method should only be callable by the coordinator or contract owner
  function setCoordinator(address vrfCoordinator) external;
}


// File @chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol@v1.3.0

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.4;



/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinatorV2Plus.
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBaseV2Plus, and can
 * @dev initialize VRFConsumerBaseV2Plus's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumerV2Plus is VRFConsumerBaseV2Plus {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _subOwner)
 * @dev       VRFConsumerBaseV2Plus(_vrfCoordinator, _subOwner) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create a subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords, extraArgs),
 * @dev see (IVRFCoordinatorV2Plus for a description of the arguments).
 *
 * @dev Once the VRFCoordinatorV2Plus has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBaseV2Plus.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2Plus is IVRFMigratableConsumerV2Plus, ConfirmedOwner {
  error OnlyCoordinatorCanFulfill(address have, address want);
  error OnlyOwnerOrCoordinator(address have, address owner, address coordinator);
  error ZeroAddress();

  // s_vrfCoordinator should be used by consumers to make requests to vrfCoordinator
  // so that coordinator reference is updated after migration
  IVRFCoordinatorV2Plus public s_vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) ConfirmedOwner(msg.sender) {
    if (_vrfCoordinator == address(0)) {
      revert ZeroAddress();
    }
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2Plus expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
  function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external {
    if (msg.sender != address(s_vrfCoordinator)) {
      revert OnlyCoordinatorCanFulfill(msg.sender, address(s_vrfCoordinator));
    }
    fulfillRandomWords(requestId, randomWords);
  }

  /**
   * @inheritdoc IVRFMigratableConsumerV2Plus
   */
  function setCoordinator(address _vrfCoordinator) external override onlyOwnerOrCoordinator {
    if (_vrfCoordinator == address(0)) {
      revert ZeroAddress();
    }
    s_vrfCoordinator = IVRFCoordinatorV2Plus(_vrfCoordinator);

    emit CoordinatorSet(_vrfCoordinator);
  }

  modifier onlyOwnerOrCoordinator() {
    if (msg.sender != owner() && msg.sender != address(s_vrfCoordinator)) {
      revert OnlyOwnerOrCoordinator(msg.sender, owner(), address(s_vrfCoordinator));
    }
    _;
  }
}


// File @openzeppelin/contracts/utils/Context.sol@v5.2.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}


// File @openzeppelin/contracts/utils/Pausable.sol@v5.2.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File @openzeppelin/contracts/utils/ReentrancyGuard.sol@v5.2.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.1.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}


// File contracts/IFarshot.sol

// Original license: SPDX_License_Identifier: MIT
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


// File contracts/Farshot.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.28;





/// @title Farshot
/// @notice Contract for handling a chance-based game using Chainlink VRF for randomness
/// @dev Implements VRFConsumerBaseV2Plus for random number generation, Pausable for emergency stops, and ReentrancyGuard for security
contract Farshot is VRFConsumerBaseV2Plus, IFarshot, Pausable, ReentrancyGuard {

    /// @notice Maximum bet as a percentage of contract balance (1%)
    uint256 public constant MAX_BET_PERCENT = 100;
    /// @notice Basis points constant for percentage calculations (100%)
    uint256 private constant BASIS_POINTS = 10000;
    /// @notice Threshold for 40.6% win chance
    uint256 public constant NUMBER_TO_BEAT_1 = 68896293096203136277024736080169305172695640876056135603477262484708312135761;
    /// @notice Threshold for 30.1% win chance
    uint256 public constant NUMBER_TO_BEAT_2 = 81054462466121336796499689506081535497288989265948394827620308805539190747954;
    /// @notice Threshold for 19.6% win chance
    uint256 public constant NUMBER_TO_BEAT_3 = 93212631836039537315974642931993765821882337655840654051763355126370069360147;
    /// @notice Threshold for 14.4% win chance
    uint256 public constant NUMBER_TO_BEAT_4 = 99233820476379979478000334152445537030252376858453963381815149494781552101424;
    /// @notice Threshold for 9.1% win chance
    uint256 public constant NUMBER_TO_BEAT_5 = 105370801205957737835449596357905996146475686045732913275906401447200947972340;

    /// @notice Address of the contract administrator
    address public admin;
    /// @notice Timestamp when the contract was last paused
    uint256 public pauseTime;
    /// @notice VRF key hash for BASE 30 gwei hash lane
    bytes32 public keyHash;
    /// @notice Gas limit for VRF callback
    uint32 public callbackGasLimit;
    /// @notice Number of confirmations required for VRF request
    uint16 public requestConfirmations;
    /// @notice Number of random words to request from VRF
    uint32 public numWords;
    /// @notice VRF subscription ID
    uint256 public s_subscriptionId;
    /// @notice ID of the most recent VRF request
    uint256 public lastRequestId;

    /// @notice Mapping of request IDs to their status details
    mapping(uint256 => RequestStatus) public s_requests;
    /// @notice Mapping of multiplier levels to their configuration details
    mapping(uint8 => Multiplier) public multipliers;

    /// @notice Ensures function can only be called by admin
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
        multipliers[1] = Multiplier({ numberToBeat: NUMBER_TO_BEAT_1, winMultiplier: 10000 }); // 100%
        multipliers[2] = Multiplier({ numberToBeat: NUMBER_TO_BEAT_2, winMultiplier: 15000 }); // 150%
        multipliers[3] = Multiplier({ numberToBeat: NUMBER_TO_BEAT_3, winMultiplier: 20000 }); // 200%
        multipliers[4] = Multiplier({ numberToBeat: NUMBER_TO_BEAT_4, winMultiplier: 25000 }); // 250%
        multipliers[5] = Multiplier({ numberToBeat: NUMBER_TO_BEAT_5, winMultiplier: 30000 }); // 300%
    }

    /// @notice Allows the contract to receive ETH
    receive() external payable {}

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
     * @notice Allows the admin to set a new admin address.
     * @param _admin The new admin address.
     */
    function setAdmin(address _admin) external onlyAdmin {
        if (_admin == address(0)) {
            revert InvalidAdminAddress();
        }
        admin = _admin;
    }

    /**
     * @notice Requests random words from Chainlink VRF for a player's game bet.
     * @param player The address of the player.
     * @param multiplier The selected multiplier (allowed values: 1, 2, 3, 4, or 5).
     * @return requestId The unique identifier of the VRF request.
     */
    function requestRandomWords(
        address player,
        uint8 multiplier
    ) external payable whenNotPaused nonReentrant returns (uint256 requestId) {
        // Validate bet value
        if (address(this).balance == 0) {
            revert InvalidValue();
        }

        // Determine the contract balance before the current deposit
        uint256 currentBalance = address(this).balance - msg.value;
        uint256 maxCurrentBet = _calculatePercentage(currentBalance, MAX_BET_PERCENT);
        
        if (currentBalance == 0 || msg.value > maxCurrentBet){
            revert InvalidValue();
        }

        // Validate the multiplier selection
        if (multiplier != 1 && multiplier != 2 && multiplier != 3 && multiplier != 4 && multiplier != 5) {
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
                        nativePayment: true
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
        uint256 playerValue = s_requests[_requestId].value;

        uint8 multiplier = s_requests[_requestId].multiplier;
        uint256 numberToBeat = multipliers[multiplier].numberToBeat;
        uint256 payout;

        // Check if the random word meets the win condition
        if (_randomWords[0] >= numberToBeat) {
            uint256 winAmount = playerValue + ((playerValue * multipliers[multiplier].winMultiplier) / BASIS_POINTS);
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
    function withdraw() external onlyAdmin nonReentrant 
    {   
        if ( !paused() || block.timestamp < pauseTime + 24 hours) {
            revert WithdrawTimeInvalid();
        }
        (bool success, ) = admin.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    /**
   * @notice Calculates percentage of an amount using basis points
   * @dev Used for fee calculations
   * @param amount The amount to calculate the percentage of
   * @param basisPoints The basis points representing the percentage
   * @return The calculated percentage of the amount
   */
  function _calculatePercentage(
    uint256 amount,
    uint256 basisPoints
  ) internal pure returns (uint256) {
    if (basisPoints == 0 || amount == 0) {
      return 0;
    }
    if (basisPoints > BASIS_POINTS) {
      revert InvalidReferralFeePercentage();
    }
    return (amount * basisPoints) / BASIS_POINTS;
  }
}
