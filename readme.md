# Pharos Agent Kit: DEVELOPER TOOLING

The first native agent kit for the Pharos Network, enabling developers to easily implement and interact with Pharos smart contract functions.

# Pharos Network Agent Kit Smart Contracts: CUSTOM BUILT
The contracts implement a decentralized finance (DeFi) system that includes a vault for collateralized stablecoin minting, a liquidity pool for token swaps, and an ERC20 token contract. Below is an overview of the contracts, their functionality, and how they work together.

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

## Contract Addresses & Links

### Smart Contracts
- PharosSwap Contract: [`0x65B4Ae254B2B172eb5F4D495aBfF9A39Ac376d87`](https://pharosscan.xyz/address/0x65B4Ae254B2B172eb5F4D495aBfF9A39Ac376d87?tab=txs)
- Token A Contract: [`0xA22E754485D37EbC662141d06fEf3119ddd9Ec53`](https://pharosscan.xyz/address/0xA22E754485D37EbC662141d06fEf3119ddd9Ec53)
- Token B (Stable Coin) Contract: [`0xb0b2d1e56328EB6f7e5c9139e7BA4b47A02C7acD`](https://pharosscan.xyz/address/0xb0b2d1e56328EB6f7e5c9139e7BA4b47A02C7acD)

### Package Installation
The Pharos Agent Kit is available on npm: [pharosagent](https://www.npmjs.com/package/pharosagent)

Install using npm:
```bash
npm i pharosagent
```

Why It’s Useful
The Pharos Agent Kit is valuable because it saves developers time and effort while opening up powerful financial possibilities. Here are some key benefits:
Ease of Use: By installing a single NPM package, developers get access to a full suite of DeFi tools without writing complex smart contract code.

Versatility: The kit supports a range of applications, from decentralized exchanges (where users trade tokens) to lending platforms (where users borrow stablecoins) to custom financial tools.

Pharos Network Optimization: The kit is tailored for the Pharos Network, which is designed for fast, secure, and cost-effective transactions, making it ideal for DeFi applications.

Scalability: Developers can build small prototypes or large-scale applications, as the tools are designed to handle various levels of complexity.

Community and Growth: By building on the Pharos Network, developers join a growing ecosystem of DeFi projects, with opportunities to collaborate and innovate.

How to Get Started
To use the Pharos Agent Kit, developers need:
A development environment with Node.js and NPM installed.

Access to the Pharos Network, either through its main network (Mainnet) or a testing network (Devnet).

A digital wallet with some Pharos Network tokens to pay for transaction fees.

Once set up, developers can install the package with npm i pharosagent, follow the documentation to configure their connection, and start using the tools. The kit includes example code to show how to perform common tasks, like setting up a vault or adding liquidity, making it easy to get started.
Important Notes
Contract Addresses: The addresses listed above (0x123..., 0xabc..., 0x789...) are placeholders. Developers must use the actual addresses of the deployed contracts on the Pharos Network (check the project’s official documentation or repository for these).

Security: Before using the kit in a live application, developers should verify the contract addresses and ensure their application is secure. The kit’s token management tools, for example, may need restrictions to prevent unauthorized actions like creating unlimited tokens.

Testing: Developers can test their applications on the Pharos Devnet, a testing environment where they can experiment without using real money.

Support: The Pharos Agent Kit team provides support through email, a community Discord, or GitHub issues (details available in the project repository).

Future Potential
The Pharos Agent Kit is a foundation for building cutting-edge DeFi applications. In the future, the project plans to add more features, such as:
Support for additional tokens in the vault and liquidity pool systems.

Tools for governance, allowing users to vote on system changes.

Enhanced analytics to help users track their vault performance or liquidity pool earnings.

Integration with other blockchain networks for cross-chain functionality.

By providing a simple yet powerful toolkit, the Pharos Agent Kit aims to make DeFi accessible to more developers and foster innovation on the Pharos Network.
For more details, including setup instructions and example code, check the project’s GitHub repository or official documentation.



## Getting Started

https://www.npmjs.com/package/pharosagent

### Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- OpenAI API key (for AI features)

### Installation

```bash
npm install
```