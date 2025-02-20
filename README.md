# Farshot Smart Contract

Farshot is a chance-based game smart contract built on Base that uses Chainlink VRF (Verifiable Random Function) for secure randomness generation.

## Overview

The contract implements a betting game where players can:

- Place bets with different multiplier options (1x, 2x, 3x, 4x, 5x)
- Win based on verifiable random numbers from Chainlink VRF
- Receive automatic payouts when winning

## Key Features

- **Fair Randomness**: Utilizes Chainlink VRF for provably fair random number generation
- **Multiple Betting Options**: Five different risk/reward levels (multipliers)
- **Safety Mechanisms**:
  - Pausable functionality
  - Reentrancy protection
  - Bet size limits
  - Maximum bet as percentage of contract balance
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
- Modify VRF parameters
