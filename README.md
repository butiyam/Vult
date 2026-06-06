
# Vult ZK-Uniswap v4 Protocol Deployment Guide

This repository contains the complete smart contract architecture for the Vult Zero-Knowledge Uniswap v4 Hook system. Follow this guide to configure your environment and deploy the entire pipeline to the Ethereum Sepolia testnet sequentially.

---

## 🛠️ Software Prerequisites (Windows via WSL2)

Before starting, ensure your Ubuntu environment has the following toolchains installed:
* **Foundry / Forge** (`foundryup`)
* **Node.js (v20+ or v22+)** & `npm`
* **SnarkJS** (`npm install -g snarkjs`)
* **Circom Compiler** (`v2.1.6+`)

---

## ⚙️ Step 1: Environment Setup

Create a `.env` file in the root directory of the project to securely house your sensitive API keys and cryptographic variables:

```bash
# Open environment file
nano .env
