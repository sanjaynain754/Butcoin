// BUT Network - Data Segment Structures (Confusion Layer)
#pragma once
#include <string>
#include <vector>
#include <cstdint>
#include <chrono>
#include <sstream>
#include <iomanip>
#include <openssl/sha.h>

namespace but { namespace core {

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
inline std::string double_sha512_hex(const std::vector<uint8_t>& data) {
    uint8_t hash1[SHA512_DIGEST_LENGTH], hash2[SHA512_DIGEST_LENGTH];
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

constexpr uint64_t BITES_PER_BUT = 1000;
constexpr uint64_t TOTAL_BUT_SUPPLY = 21'000'000;
constexpr uint64_t TOTAL_BITES_SUPPLY = TOTAL_BUT_SUPPLY * BITES_PER_BUT;

enum class SecurityLevel : uint8_t { STANDARD_512 = 0x01, VAULT_1024 = 0x02, QUANTUM = 0x03 };
enum class TransactionType : uint8_t { STANDARD_TRANSFER = 0x01, VAULT_TRANSFER = 0x02, CONTRACT_EXECUTION = 0x03, NAME_REGISTRATION = 0x04, SOCIAL_RECOVERY = 0x05 };

struct FeeCalculator {
    static constexpr uint64_t K1 = 100000;   // 1,00,000 Bites
    static constexpr uint64_t K2 = 1000000;  // 10,00,000 Bites
    static constexpr uint64_t E1 = 20;       // 20%
    static constexpr uint64_t E2 = 50;       // 50%
    static constexpr uint64_t E3 = 70;       // 70%
    static constexpr uint64_t SF = 50;       // 50% dev share

    static uint64_t check_overflow(uint64_t x) {
        if (x == 0) return 0;
        uint64_t r = E1;
        if (x > K2) r = E3;
        else if (x > K1) r = E2;
        uint64_t f = (x * r) / 100;
        return (f == 0) ? 1 : f;
    }

    static uint64_t fragment_A(uint64_t total) { return (total * SF) / 100; }
    static uint64_t fragment_B(uint64_t total) { return total - fragment_A(total); }
};

struct SignalFragment {
    std::string fragment_id, source, destination, data_hash;
    uint64_t amount, fee;
    int64_t timestamp;
    std::vector<uint8_t> signature;
    SecurityLevel sec_level;
    TransactionType tx_type;
    double amount_in_but() const { return static_cast<double>(amount) / BITES_PER_BUT; }
    double fee_in_but() const { return static_cast<double>(fee) / BITES_PER_BUT; }
    uint64_t total_cost_bites() const { return amount + fee; }
    std::string compute_id() const {
        std::stringstream ss;
        ss << source << destination << amount << fee << timestamp;
        return (sec_level == SecurityLevel::VAULT_1024) ? double_sha512_hex(ss.str()) : sha512_hex(ss.str());
    }
    bool validate() const {
        return !source.empty() && !destination.empty() && amount > 0 && fee > 0 &&
               timestamp > 0 && (amount + fee) <= TOTAL_BITES_SUPPLY;
    }
};

struct DataSegment {
    std::string segment_id, previous_hash, merkle_root, validator_sig;
    int64_t timestamp;
    uint64_t height;
    std::vector<SignalFragment> fragments;
    SecurityLevel sec_level;
    uint32_t nonce;
    std::string compute_hash() const {
        std::stringstream ss;
        ss << previous_hash << timestamp << height << merkle_root << nonce;
        return (sec_level == SecurityLevel::VAULT_1024) ? double_sha512_hex(ss.str()) : sha512_hex(ss.str());
    }
};

inline DataSegment create_genesis_block() {
    DataSegment g;
    g.segment_id = "BUT_GENESIS_2024";
    g.previous_hash = std::string(128, '0');
    g.timestamp = std::chrono::system_clock::now().time_since_epoch().count();
    g.height = 0;
    g.sec_level = SecurityLevel::VAULT_1024;
    g.nonce = 0;
    g.merkle_root = sha512_hex("BUT_NETWORK_GENESIS");
    g.validator_sig = "GENESIS_VALIDATOR";
    return g;
}

}} // namespace but::core
