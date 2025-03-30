# GeniDex Smart Contracts

GeniDex is a decentralized exchange (DEX) powered entirely by smart contracts and designed around a scalable on-chain order book. It supports multi-chain deployments and integrates a point-based incentive system that rewards users with GENI tokens.

---

## 📦 Contract Structure

- **GeniDex.sol** – Main contract integrating core modules like BuyOrders, SellOrders, Balances, and Markets.
- **BuyOrders.sol / SellOrders.sol** – Handle order placement, matching, and event emission.
- **Markets.sol** – Market creation, price precision calculation, and configuration.
- **Balances.sol** – Manages internal balances for each trader.
- **Tokens.sol** – List of supported tokens and metadata.
- **Points.sol** – Calculates and tracks user trading points.
- **Storage.sol / Helper.sol** – Shared storage layout and common utilities.

---

## 🏆 Reward System

The reward system distributes GENI tokens based on points users earn from trading. Key mechanics:

- Points are earned based on trading volume (in USD).
- GENI tokens are unlocked linearly every minute within an epoch.
- Epochs last 12 months; only half of the contract balance is allocated for each epoch.
- Users can claim at any time based on the formula:
  
  ```
  tokenPerPoint = unlocked / totalUnclaimedPoints
  reward = pointsToClaim * tokenPerPoint
  ```

---

## 🔐 Security Features

- **Upgradeable**: Uses UUPS proxy with OpenZeppelin’s `OwnableUpgradeable` and `UUPSUpgradeable`.
- **Emergency Stop**: Integrated `PausableUpgradeable` to allow pausing in case of critical issues.
- **Reentrancy Protection**: Critical methods use `nonReentrant` to prevent reentrancy attacks.

---

## 🚀 Deployment

1. Install dependencies:
   ```bash
   npm install
   ```

2. Compile contracts:
   ```bash
   npx hardhat compile
   ```

3. Deploy contracts:
   ```bash
   npx hardhat run scripts/deploy.ts --network <network-name>
   ```

---

## 🧪 Testing

Run all unit tests using Hardhat:
```bash
npx hardhat test
```

---

## 🌐 Website

Visit our website: [https://genidex.org](https://genidex.org)

---

## 📄 License

MIT License © 2025 Geni Team