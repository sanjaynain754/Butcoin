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
    for (int i = 0; i < SHA512_DIGEST_LENGTH; ++i)
        ss << std::hex << std::setw(2) << std::setfill('0') << (int)hash1[i];
    for (int i = 0; i < SHA512_DIGEST_LENGTH; ++i)
        ss << std::hex << std::setw(2) << std::setfill('0') << (int)hash2[i];
    return ss.str();
}

inline std::string double_sha512_hex(const std::string& data) {
    std::vector<uint8_t> bytes(data.begin(), data.end());
    return double_sha512_hex(bytes);
}

// ==================== BUT Currency Constants ====================

constexpr uint64_t BITES_PER_BUT = 1000;
constexpr uint64_t TOTAL_BUT_SUPPLY = 21'000'000;
constexpr uint64_t TOTAL_BITES_SUPPLY = TOTAL_BUT_SUPPLY * BITES_PER_BUT;

// ==================== Security Level ====================

enum class SecurityLevel : uint8_t {
    STANDARD_512 = 0x01,
    VAULT_1024   = 0x02,
    QUANTUM      = 0x03
};

// ==================== Transaction Type ====================

enum class TransactionType : uint8_t {
    STANDARD_TRANSFER  = 0x01,
    VAULT_TRANSFER     = 0x02,
    CONTRACT_EXECUTION = 0x03,
    NAME_REGISTRATION  = 0x04,
    SOCIAL_RECOVERY    = 0x05
};

// ==================== Fee Calculator ====================

struct FeeCalculator {
    static uint64_t calculate_fee(TransactionType type, uint64_t amount_bites) {
        uint64_t base_fee = 1;
        switch (type) {
            case TransactionType::STANDARD_TRANSFER:
                return std::max(base_fee, amount_bites / 1000);
            case TransactionType::VAULT_TRANSFER:
                return std::max(uint64_t(5), amount_bites / 500);
            case TransactionType::CONTRACT_EXECUTION:
                return 10 + (amount_bites / 200);
            case TransactionType::NAME_REGISTRATION:
                return 50;
            case TransactionType::SOCIAL_RECOVERY:
                return 100;
            default:
                return base_fee;
        }
    }
};

// ==================== Signal Fragment (Transaction) ====================

struct SignalFragment {
    std::string fragment_id;
    std::string source;
    std::string destination;
    uint64_t    amount;
    uint64_t    fee;
    int64_t     timestamp;
    std::vector<uint8_t> signature;
    SecurityLevel sec_level;
    TransactionType tx_type;
    std::string data_hash;

    double amount_in_but() const {
        return static_cast<double>(amount) / BITES_PER_BUT;
    }

    double fee_in_but() const {
        return static_cast<double>(fee) / BITES_PER_BUT;
    }

    uint64_t total_cost_bites() const {
        return amount + fee;
    }

    std::string compute_id() const {
        std::stringstream ss;
        ss << source << destination << amount << fee << timestamp;
        if (sec_level == SecurityLevel::VAULT_1024) {
            return double_sha512_hex(ss.str());
        }
        return sha512_hex(ss.str());
    }

    bool validate() const {
        if (source.empty() || destination.empty()) return false;
        if (amount == 0) return false;
        if (fee == 0) return false;
        if (timestamp <= 0) return false;
        if (amount + fee > TOTAL_BITES_SUPPLY) return false;
        return true;
    }
};

// ==================== Data Segment (Block) ====================

struct DataSegment {
    std::string segment_id;
    std::string previous_hash;
    int64_t     timestamp;
    uint64_t    height;
    std::vector<SignalFragment> fragments;
    std::string merkle_root;
    std::string validator_sig;
    SecurityLevel sec_level;
    uint32_t    nonce;

    std::string compute_hash() const {
        std::stringstream ss;
        ss << previous_hash << timestamp << height << merkle_root << nonce;
        if (sec_level == SecurityLevel::VAULT_1024) {
            return double_sha512_hex(ss.str());
        }
        return sha512_hex(ss.str());
    }

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
    genesis.previous_hash = std::string(128, '0');
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
