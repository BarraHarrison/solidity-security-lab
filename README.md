# Solidity Security Labs

A hands-on security-focused Solidity project that demonstrates **real-world smart contract vulnerabilities** and their **correct defensive patterns**. This repository is structured as a progressive lab series, where each module introduces a common class of Ethereum attack, shows how it can be exploited, and then implements a secure alternative.

The goal of this project is **not just to write secure contracts**, but to **understand how and why attacks happen**, how they appear in practice, and how modern protocols defend against them.

---

## 🧪 Project Overview

Each module follows the same philosophy:

1. **Vulnerable Contract** – intentionally insecure implementation
2. **Attack Contract / Test** – demonstrates the exploit
3. **Safe Contract** – hardened version using best practices
4. **Test Suite** – proves both the attack and the fix

All tests are written using **Hardhat + Ethers.js**, with extensive logging to make exploits easy to follow.

---

## 📦 Modules Included

### Module 1 – Arithmetic Overflow / Underflow

**Topic:** Unsafe arithmetic leading to balance manipulation

* Vulnerable contract using unchecked math
* Exploit drains or inflates balances
* Safe version using Solidity ≥0.8.0 built-in overflow checks

**Key takeaway:** Never rely on implicit assumptions about arithmetic safety.

---

### Module 2 – Reentrancy Attacks

**Topic:** External calls before state updates

* Classic reentrancy vulnerability
* Attacker contract drains funds recursively
* Safe implementation using:

  * Checks-Effects-Interactions pattern
  * Reentrancy guards

**Key takeaway:** Always update state before external calls.

---

### Module 3 – Access Control Failures

**Topic:** Improper role and permission management

* Missing or incorrect access checks
* Privileged functions callable by attackers
* Safe version using role-based access control

**Key takeaway:** Explicit permissions matter more than intent.

---

### Module 4 – Oracle Manipulation Attacks

**Topic:** Trusting manipulable on-chain prices

* Vulnerable oracle relying on instant pool balances
* Attacker manipulates price to drain lending protocol
* Safe oracle using:

  * Controlled updates
  * Delayed / owner-governed pricing

**Key takeaway:** Oracles must be resistant to short-term manipulation.

---

### Module 5 – Front‑Running & Transaction Ordering

**Topic:** MEV-style attacks using mempool visibility

* Vulnerable logic where order of execution matters
* Attacker front-runs victim transactions
* Safe design using commit‑reveal or invariant checks

**Key takeaway:** Assume attackers can see your transaction before it executes.

---

### Module 6 – Flash Loan Attacks & Price Manipulation

**Topic:** Zero‑capital attacks using flash liquidity

* Flash loan provider with no execution constraints
* Vulnerable DEX allows price manipulation within one transaction
* Safe DEX protects against:

  * Excessive trade sizes
  * Extreme price impact

⚠️ **Note:**
The VulnerableDEX test demonstrates how difficult it is to safely model flash‑loan exploits. While price manipulation is observable, full value extraction is intentionally constrained to avoid unrealistic assumptions. This limitation is documented in the README for transparency.

**Key takeaway:** Flash loans amplify existing weaknesses — they don’t create them.

---

### Module 7 – Signature Replay Attacks

**Topic:** Reusing valid signatures to drain funds

* Vulnerable vault accepts raw signatures
* Attacker replays the same signature multiple times
* Safe vault uses:

  * Nonce tracking
  * Signature invalidation

**Key takeaway:** A signature without a nonce is reusable forever.

---

### Module 8 – EIP‑712 Typed Data Signatures

**Topic:** Secure off‑chain authorization

* Fully implemented EIP‑712 signature vault
* Domain separation prevents:

  * Cross‑contract replay
  * Cross‑chain replay
* Tests verify:

  * Valid withdrawal succeeds
  * Replay attacks fail
  * Modified data invalidates signature

**Key takeaway:** EIP‑712 is the industry standard for secure signing.

---

## 🧠 Skills Demonstrated

* Smart contract security auditing mindset
* Real‑world exploit modeling
* Writing attacker contracts
* Designing hardened protocol logic
* Advanced testing with Hardhat & Ethers
* Debugging with detailed on‑chain logging

---

## 🛠️ Tech Stack

* Solidity ^0.8.x
* Hardhat
* Ethers.js (v6)
* Mocha / Chai

---

## 🚀 How to Run

```bash
npm install
npx hardhat compile
npx hardhat test
```

Run individual modules:

```bash
npx hardhat test test/oracle.test.js
npx hardhat test test/flashloan.test.js
npx hardhat test test/signature/eip712.test.js
```

---

## 📌 Final Notes

This project is designed as a **security learning lab**, not a production system. Vulnerabilities are intentionally introduced to demonstrate how attacks work in practice.

If you are learning smart contract security, auditing, or protocol design, this repository provides **concrete, testable examples** of the most important failure modes in Ethereum.

---

**Author:** Barra Harrison
**Focus:** Smart Contract Security · DeFi Protocol Design · Solidity Auditing