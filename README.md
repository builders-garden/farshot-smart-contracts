# Farshot Smart Contract

Farshot is a chance-based game smart contract built on Base that uses Chainlink VRF (Verifiable Random Function) for secure randomness generation.

Check the [Farshot documentation](https://builders-garden.notion.site/Farshot-documentation-1a4679ed099e80f4a1d4cd9b56b07d12?pvs=74) for more information.

## Overview

The contract implements a betting game where players can:

- Place bets with different multiplier options (2x, 2.5x, 3x, 3.5x, 4x)
- Win based on verifiable random numbers from Chainlink VRF
- Receive automatic payouts when winning

## Key Features

- **Fair Randomness**: Utilizes Chainlink VRF for provably fair random number generation
- **Multiple Betting Options**: Five different risk/reward levels (multipliers)
- **Safety Mechanisms**:
  - Pausable functionality
  - Reentrancy protection
  - Bet size limits
  - Maximum bet as 1% of contract ETH balance
  - 24-hour delay on admin withdrawals after pausing

## Technical Details

- Minimum bet: 0.00001 ETH
- Maximum bet: 1 ETH
- Maximum bet size: 1% of contract balance

## Administration

The contract includes admin functions to:

- Update VRF configuration
- Pause/unpause the contract. When paused, no new bets can be placed.
- Withdraw funds (after 24-hour cooling period when paused)