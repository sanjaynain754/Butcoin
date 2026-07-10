# 🔐 BUT Network Security Policy

## 10-Layer Security Architecture

BUT Network दुनिया का सबसे सुरक्षित ब्लॉकचेन है — 10 Security Layers के साथ।

---

## 🛡️ Security Layers Overview

| # | Code | Layer | Language | Purpose |
|---|------|-------|----------|---------|
| 1 | **CKS** | Cosmic Key Space | Rust | 512-bit & 1024-bit Base Cryptography |
| 2 | **VLT** | Vault MPC | C++ | 3-of-5 Key Sharding (Shamir) |
| 3 | **ZKF** | Zero-Knowledge Flow | C++ | Schnorr + Bulletproofs ZK Proofs |
| 4 | **AIS** | AI Shield | C++ | Real-time Behavior Analysis |
| 5 | **QSH** | Quantum Sign Handler | Rust | Dilithium-style PQ Signatures |
| 6 | **TEX** | Trusted Execution | C++ | Secure Enclave + Attestation |
| 7 | **TLK** | Time Lock | C++ | Time-lock Encryption (RSW) |
| 8 | **DID** | Decentralized Identity | C++ | W3C DID + Verifiable Credentials |
| 9 | **AIR** | Air-gapped Signing | C++ | QR/SD Card Offline Signing |
| 10 | **QRN** | Quantum Random Numbers | Rust | Multi-source Entropy (OS + CPU + Time) |

---

## 🔬 Layer Details

### Layer 1: CKS (Cosmic Key Space)
- **Type:** Base Cryptography
- **Key Sizes:** 512-bit (Standard) & 1024-bit (Vault)
- **Algorithm:** HKDF-SHA512, Double HKDF for 1024-bit
- **Randomness:** OS CSPRNG (`/dev/urandom`, SecureRandom)
- **Memory Safety:** Zeroize after use

### Layer 2: VLT (MPC Key Sharding)
- **Type:** Multi-Party Computation
- **Scheme:** Shamir's Secret Sharing (3-of-5)
- **Security:** Key never exists in one place
- **Recovery:** Minimum 3 shards required
- **Integrity:** SHA-256 checksum per shard

### Layer 3: ZKF (Zero-Knowledge Proofs)
- **Type:** Privacy-Preserving Proofs
- **Protocols:** Schnorr ZK Proofs + Bulletproofs
- **Use Cases:** Private transactions, Range proofs
- **Tamper Detection:** Built-in verification

### Layer 4: AIS (AI Shield)
- **Type:** Behavioral Analysis
- **Detection:** Rapid fire, Dust attacks, Anomalies
- **Actions:** Allow, Flag, Delay, Block
- **Learning:** Welford's online algorithm
- **Risk Score:** 0.0 (safe) to 1.0 (malicious)

### Layer 5: QSH (Quantum Signatures)
- **Type:** Post-Quantum Cryptography
- **Levels:** 128-bit, 192-bit, 256-bit quantum security
- **Basis:** Lattice-based (Dilithium-compatible)
- **NTT:** Number Theoretic Transform

### Layer 6: TEX (Trusted Execution)
- **Type:** Hardware Isolation
- **Features:** Secure Enclave, Remote Attestation
- **Operations:** Sign, Encrypt, Random (inside enclave)
- **Key Protection:** Key never leaves enclave

### Layer 7: TLK (Time Lock)
- **Type:** Temporal Encryption
- **Scheme:** Rivest-Shamir-Wagner (RSW) Puzzle
- **Use Cases:** Inheritance, Delayed TX, Dead Man's Switch
- **Anti-frontrunning:** Yes

### Layer 8: DID (Decentralized Identity)
- **Type:** Self-Sovereign Identity
- **Standard:** W3C DID + Verifiable Credentials
- **Features:** Issue, Verify, Revoke credentials
- **ZK-KYC Ready:** Yes

### Layer 9: AIR (Air-gapped Signing)
- **Type:** Offline Transaction Signing
- **Transfer Methods:** QR Code, SD Card
- **Security:** Key never touches internet
- **Verification:** Online integrity check

### Layer 10: QRN (Quantum Random Numbers)
- **Type:** True Random Number Generation
- **Entropy Sources:** OS, CPU Jitter, Nanosecond Clock
- **Tests:** Monobit, Runs, Chi-Square
- **Output:** 512-bit & 1024-bit seeds

---

## 🐛 Bug Bounty Program

| Severity | Reward (BUT) | Example |
|----------|-------------|---------|
| **Critical** | 50,000 - 100,000 | Private key leak, Chain attack |
| **High** | 10,000 - 50,000 | P2P attack, Double-spend |
| **Medium** | 1,000 - 10,000 | Wallet bug, UI exploit |
| **Low** | 100 - 1,000 | Minor bug, Cosmetic |

### How to Report:
- GitHub: [Report a Vulnerability](https://github.com/sanjaynain754/Butcoin/security/advisories/new)
- Email: security@but.network *(coming soon)*

### Rules:
- ⏰ 90-day disclosure window
- 🚫 No testing on production
- 🤝 Responsible disclosure
- 💰 First reporter gets reward

---

## ✅ Security Best Practices

- [x] OS CSPRNG (no custom randomness)
- [x] Memory wipe after key use (Zeroize)
- [x] Platform keystore (Android/iOS)
- [x] Biometric + PIN dual auth
- [x] Exponential backoff on failed attempts
- [x] Noise protocol for P2P encryption
- [x] Auto-blacklist attackers (Mirror Shield)
- [x] Permanent blacklist (Code Abyss)
- [x] MPC key sharding (3-of-5)
- [x] Zero-Knowledge proofs
- [x] AI behavior analysis
- [x] Post-Quantum signatures
- [x] Trusted execution environment
- [x] Time-lock encryption
- [x] Decentralized identity
- [x] Air-gapped signing
- [x] Quantum random numbers
- [ ] External security audit (Planned Q3 2026)
- [ ] Formal verification (Planned 2027)

---

## 🔗 Related Documents

- [README.md](README.md) — Project Overview
- [ROADMAP.md](ROADMAP.md) — Development Plan
- [CONTRIBUTING.md](CONTRIBUTING.md) — Contribution Guide

---

*Last Updated: July 10, 2026*
