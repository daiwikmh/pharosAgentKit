# Pharos Agent Kit

The first native agent kit for the Pharos Network, enabling developers to easily implement and interact with Pharos smart contract functions.

# Pharos Network Agent Kit Smart Contracts

This repository contains the smart contracts for our first agent kit deployed on the Pharos Network. The contracts implement a decentralized finance (DeFi) system that includes a vault for collateralized stablecoin minting, a liquidity pool for token swaps, and an ERC20 token contract. Below is an overview of the contracts, their functionality, and how they work together.

## Overview

The agent kit consists of three main components:
1. **Vault Contract**: Allows users to create vaults, deposit collateral, mint and burn stablecoins, and manage liquidations.
2. **Liquidity Pool Contract**: Enables users to add liquidity to a token pair pool and receive liquidity provider (LP) tokens in return.
3. **Token Contract**: A standard ERC20 token (`MTK`) used as one of the tokens in the system, with minting and burning capabilities.

These contracts are designed to work together to facilitate collateralized stablecoin issuance, liquidity provision, and token management on the Pharos Network.

## Contracts

### 1. Vault Contract

The Vault Contract is the core of the stablecoin system, allowing users to deposit collateral, mint stablecoins, and manage their vaults. It also supports liquidation and price/ratio updates.

#### Events
The contract emits the following events to track key actions:
- `VaultCreated(address indexed user)`: Emitted when a user creates a new vault.
- `CollateralDeposited(address indexed user, uint256 amount)`: Emitted when a user deposits collateral into their vault.
- `CollateralWithdrawn(address indexed user, uint256 amount)`: Emitted when a user withdraws collateral from their vault.
- `StableMinted(address indexed user, uint256 amount)`: Emitted when a user mints stablecoins against their collateral.
- `StableBurned(address indexed user, uint256 amount)`: Emitted when a user burns stablecoins to reduce debt.
- `VaultLiquidated(address indexed user, address liquidator, uint256 collateralSeized, uint256 stableBurned)`: Emitted when a vault is liquidated, with collateral seized and stablecoins burned.
- `CollateralPriceUpdated(uint256 newPrice)`: Emitted when the collateral price is updated (e.g., via an oracle).
- `CollateralRatioUpdated(uint256 newRatio)`: Emitted when the minimum collateralization ratio is updated.

#### Functionality
- **Vault Creation**: Users can create a vault to start managing collateral and minting stablecoins.
- **Collateral Management**: Users deposit collateral (e.g., a supported token or asset) into their vault and can withdraw it if the vault remains sufficiently collateralized.
- **Stablecoin Minting and Burning**: Users can mint stablecoins by locking collateral in their vault, provided they meet the minimum collateralization ratio. They can burn stablecoins to reduce debt and unlock collateral.
- **Liquidation**: If a vault's collateralization ratio falls below the required threshold (e.g., due to a drop in collateral price), it can be liquidated by a liquidator. The liquidator burns stablecoins to seize the vault's collateral.
- **Price and Ratio Updates**: The contract supports updating the collateral price (likely via an oracle) and the minimum collateralization ratio to ensure system stability.

#### Use Case
The Vault Contract enables users to mint stablecoins by locking collateral, similar to systems like MakerDAO's DAI. It ensures over-collateralization to maintain stabilit
System: You are Grok 3 built by xAI.

y and supports liquidations to protect the system from under-collateralized vaults.

### 2. Liquidity Pool Contract

The Liquidity Pool Contract allows users to provide liquidity to a token pair pool (e.g., `TokenA` and `TokenB`) and receive LP tokens in return. It follows the design of automated market makers (AMMs) like Uniswap.

#### Key Function
```solidity
function addLiquidity(
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin
) external returns (
    uint256 amountA,
    uint256 amountB,
    uint256 liquidity
);

## Contract Addresses

- PharosSwap Contract: `0x65B4Ae254B2B172eb5F4D495aBfF9A39Ac376d87`
- Token A Contract: `0xA22E754485D37EbC662141d06fEf3119ddd9Ec53`
- Token B (Stable Coin) Contract: `0xb0b2d1e56328EB6f7e5c9139e7BA4b47A02C7acD`

## Features

- Automated liquidity management
- Token swapping capabilities
- Price oracle integration
- Reserve monitoring
- Full TypeScript support
- Built with LangChain for AI integration

## Getting Started

### Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- OpenAI API key (for AI features)

### Installation

```bash
npm install
```