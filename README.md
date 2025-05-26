# Auction Smart Contract

A simple Ethereum smart contract for a time-bound auction with secure bidding, built using Solidity, Truffle, and Infura.

## 🚀 Features

- Owner-controlled auction with start/end blocks
- Secure bid placement with `highestBindingBid`
- Reentrancy guard and `finalizeAuction` logic
- Cancelable auction with refund system
- IPFS hash reference (for storing metadata/images)

---

## 🧱 Tech Stack

- Solidity ^0.8.0
- Truffle Framework
- Ganache (for local blockchain)
- Infura (for testnet deployment)
- @truffle/hdwallet-provider

---

## 📦 Project Structure

📁 contracts/
└── Auction.sol

📁 migrations/
└── 1_deploy_contracts.js

📁 test/
└── (optional test files)

📄 truffle-config.js
📄 .secret ← contains your mnemonic (12-word seed phrase)
📄 README.md


---

## ⚙️ Installation

```bash
# Clone the repo
git clone https://github.com/your-username/auction-contract.git
cd auction-contract

# Install dependencies
npm install

# Install Truffle globally if not yet installed
npm install -g truffle

⚗️ Development
Compile the contract
truffle compile
Start local blockchain (Ganache)

ganache-cli
Migrate to local network
truffle migrate --network development

🌍 Deploy to Sepolia Testnet
1. Create .secret file
Save your MetaMask mnemonic (12 words) inside .secret file:
arduino
twelve word mnemonic goes here

⚠️ Ensure this file is in .gitignore!

2. Add your Infura Project ID
In truffle-config.js, replace YOUR_INFURA_PROJECT_ID with your actual Infura project ID.

3. Deploy
truffle migrate --network sepolia

🧪 Test (Optional)
You can write test scripts inside the test/ folder using Mocha/Chai or Web3.js.

Run tests with:
truffle test

📜 License
This project is licensed under the GPL-3.0 License.

