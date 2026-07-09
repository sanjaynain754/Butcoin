# 🔐 BUT Network Security Policy

## सिक्योरिटी आर्किटेक्चर

| लेयर | टेक्नोलॉजी |
|-------|------------|
| Crypto | CKS-512, CKS-1024, Hybrid (Rust) |
| Keys | BUT-S (Spend) + BUT-V (View) |
| Storage | Android Keystore / iOS Keychain |
| Network | Noise IK, Mirror Shield, Onion |
| Blockchain | QR Merkle Tree (SHA-512/1024) |

---

## 🐛 Bug Bounty

| गंभीरता | रिवॉर्ड |
|----------|---------|
| Critical | 50,000 - 100,000 BUT |
| High | 10,000 - 50,000 BUT |
| Medium | 1,000 - 10,000 BUT |
| Low | 100 - 1,000 BUT |

### रिपोर्ट कैसे करें:
- GitHub: [Report a Vulnerability](https://github.com/sanjaynain754/Butcoin/security/advisories/new)

---

## ✅ Best Practices

- [x] OS CSPRNG (कोई custom randomness नहीं)
- [x] Memory wipe (Zeroize)
- [x] Platform keystore
- [x] Biometric + PIN
- [x] Exponential backoff
- [ ] External Audit (Planned)
- [ ] Formal Verification (Planned)
