// BUT Network - Data Segment Structures
// Block & Transaction definitions with dual 512/1024-bit hashing

#pragma once

#include <string>
#include <vector>
#include <cstdint>
#include <chrono>
#include <sstream>
#include <iomanip>
#include <openssl/sha.h>

namespace but {
namespace core {

// ==================== Utility: Hash Helpers ====================

inline std::string sha512_hex(const std::vector<uint8_t>& data) {
    uint8_t hash[SHA512_DIGEST_LENGTH];
    SHA512(data.data(), data.size(), hash);
    std::stringstream ss;
    for (int i = 0; i < SHA512_DIGEST_LENGTH; ++i)
        ss << std::hex << std::setw(2) << std::setfill('0') << (int)hash[i];
    return ss.str();
}

inline std::string sha512_hex(const std::string& data) {
    std::vector<uint8_t> bytes(data.begin(), data.end());
    return sha512_hex(bytes);
}

// Double SHA-512 for 1024-bit equivalent security
inline std::string double_sha512_hex(const std::vector<uint8_t>& data) {
    uint8_t hash1[SHA512_DIGEST_LENGTH];
    uint8_t hash2[SHA512_DIGEST_LENGTH];
    SHA512(data.data(), data.size(), hash1);
    SHA512(hash1, SHA512_DIGEST_LENGTH, hash2);
    std::stringstream ss;
    // Concatenate both hashes for 1024-bit output
    for (int i = 0; i < SHA512_DIGEST_LENGTH; ++i)
        ss << std::hex << std::setw(2) << std::setfill('0') << (int)hash1[i];
    for (int i = 0; i < SHA512_DIGEST_LENGTH; ++i)
        ss << std::hex << std::setw(2) << std::setfill('0') << (int)hash2[i];
    return ss.str();
}

// ==================== Transaction (Signal Fragment) ====================

enum class SecurityLevel : uint8_t {
    STANDARD_512 = 0x01,
    VAULT_1024   = 0x02,
    QUANTUM      = 0x03
};

struct SignalFragment {
    std::string fragment_id;       // Transaction ID
    std::string source;            // Sender (BUT-S key)
    std::string destination;       // Receiver (but://username or address)
    uint64_t    amount;            // Amount in satoshis
    int64_t     timestamp;         // Unix timestamp
    std::vector<uint8_t> signature; // Hybrid signature
    SecurityLevel sec_level;       // 512 or 1024
    std::string data_hash;         // Hash of extra data

    // Generate transaction ID based on contents
    std::string compute_id() const {
        std::stringstream ss;
        ss << source << destination << amount << timestamp;
        if (sec_level == SecurityLevel::VAULT_1024) {
            return double_sha512_hex(ss.str());
        }
        return sha512_hex(ss.str());
    }

    // Validate transaction
    bool validate() const {
        if (source.empty() || destination.empty()) return false;
        if (amount == 0) return false;
        if (timestamp <= 0) return false;
        return true;
    }
};

// ==================== Block (Data Segment) ====================

struct DataSegment {
    std::string segment_id;        // Block hash
    std::string previous_hash;     // Previous block hash (512 or 1024)
    int64_t     timestamp;         // Block creation time
    uint64_t    height;            // Block number
    std::vector<SignalFragment> fragments; // Transactions
    std::string merkle_root;       // Merkle tree root (512 or 1024)
    std::string validator_sig;     // Validator signature
    SecurityLevel sec_level;       // Security level
    uint32_t    nonce;             // For Proof-of-Connection

    // Compute block hash
    std::string compute_hash() const {
        std::stringstream ss;
        ss << previous_hash << timestamp << height << merkle_root << nonce;
        if (sec_level == SecurityLevel::VAULT_1024) {
            return double_sha512_hex(ss.str());
        }
        return sha512_hex(ss.str());
    }

    // Validate block structure
    bool validate_structure() const {
        if (previous_hash.empty() && height != 0) return false;
        if (timestamp <= 0) return false;
        if (merkle_root.empty()) return false;
        return true;
    }
};

// ==================== Genesis Block Creator ====================

inline DataSegment create_genesis_block() {
    DataSegment genesis;
    genesis.segment_id    = "BUT_GENESIS_2024";
    genesis.previous_hash = std::string(128, '0'); // 1024-bit zeros
    genesis.timestamp     = std::chrono::system_clock::now().time_since_epoch().count();
    genesis.height        = 0;
    genesis.sec_level     = SecurityLevel::VAULT_1024;
    genesis.nonce         = 0;
    genesis.merkle_root   = sha512_hex("BUT_NETWORK_GENESIS");
    genesis.validator_sig = "GENESIS_VALIDATOR";
    return genesis;
}

} // namespace core
} // namespace but
