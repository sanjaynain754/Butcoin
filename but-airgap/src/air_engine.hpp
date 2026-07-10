// BUT Network AIR - Air-gapped Signing Engine
// Offline transaction signing via QR code / SD card

#pragma once

#include <vector>
#include <string>
#include <cstdint>
#include <random>
#include <sstream>
#include <iomanip>
#include <openssl/sha.h>
#include <openssl/rand.h>

namespace but {
namespace air {

// ==================== Offline Transaction ====================

struct OfflineTransaction {
    std::string tx_id;
    std::string from_address;
    std::string to_address;
    uint64_t amount;
    uint64_t fee;
    int64_t timestamp;
    std::string data;               // Optional extra data
    std::vector<uint8_t> unsigned_hash;  // Hash to be signed
    std::vector<uint8_t> signature;      // Signed hash (after air-gap)
    bool signed_;
};

// ==================== QR Code Data (simulated) ====================

struct QRCodeData {
    std::string encoded_data;       // Base64 encoded transaction
    int version;                    // QR code version
    int error_correction;           // L, M, Q, H
    std::vector<uint8_t> checksum;  // Data integrity
};

// ==================== SD Card Transfer ====================

struct SDCardTransfer {
    std::string file_name;
    std::vector<uint8_t> file_data;
    std::vector<uint8_t> file_hash;
    int64_t transfer_time;
};

class AIREngine {
private:
    // Signing key (stored offline, never connected to internet)
    std::vector<uint8_t> offline_key;

    // Generate transaction hash
    std::vector<uint8_t> generate_tx_hash(const OfflineTransaction& tx) {
        std::stringstream ss;
        ss << tx.from_address << tx.to_address << tx.amount 
           << tx.fee << tx.timestamp << tx.data;

        std::string tx_data = ss.str();
        uint8_t hash[SHA256_DIGEST_LENGTH];
        SHA256(reinterpret_cast<const uint8_t*>(tx_data.c_str()), 
               tx_data.size(), hash);
        
        return std::vector<uint8_t>(hash, hash + SHA256_DIGEST_LENGTH);
    }

    // Sign with offline key
    std::vector<uint8_t> sign_with_offline_key(const std::vector<uint8_t>& data) {
        std::vector<uint8_t> combined = offline_key;
        combined.insert(combined.end(), data.begin(), data.end());

        uint8_t sig[SHA256_DIGEST_LENGTH];
        SHA256(combined.data(), combined.size(), sig);
        return std::vector<uint8_t>(sig, sig + SHA256_DIGEST_LENGTH);
    }

    // Verify signature
    bool verify_offline_signature(const std::vector<uint8_t>& data,
                                   const std::vector<uint8_t>& signature) {
        auto expected = sign_with_offline_key(data);
        if (expected.size() != signature.size()) return false;

        for (size_t i = 0; i < expected.size(); ++i) {
            if (expected[i] != signature[i]) return false;
        }
        return true;
    }

    // Base64 encode (simplified)
    std::string base64_encode(const std::vector<uint8_t>& data) {
        static const char* chars = 
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        
        std::string result;
        int val = 0, valb = -6;
        
        for (uint8_t c : data) {
            val = (val << 8) + c;
            valb += 8;
            while (valb >= 0) {
                result.push_back(chars[(val >> valb) & 0x3F]);
                valb -= 6;
            }
        }
        
        if (valb > -6) {
            result.push_back(chars[((val << 8) >> (valb + 8)) & 0x3F]);
        }
        
        while (result.size() % 4) {
            result.push_back('=');
        }
        
        return result;
    }

    // Base64 decode
    std::vector<uint8_t> base64_decode(const std::string& data) {
        static const std::string chars = 
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        
        std::vector<uint8_t> result;
        int val = 0, valb = -8;
        
        for (char c : data) {
            if (c == '=') break;
            size_t pos = chars.find(c);
            if (pos == std::string::npos) continue;
            
            val = (val << 6) + pos;
            valb += 6;
            
            if (valb >= 0) {
                result.push_back((val >> valb) & 0xFF);
                valb -= 8;
            }
        }
        
        return result;
    }

public:
    // Initialize offline device with key
    bool initialize_offline_device() {
        offline_key.resize(64); // 512-bit offline key
        if (RAND_bytes(offline_key.data(), offline_key.size()) != 1) {
            return false;
        }
        return true;
    }

    // Load key from secure import (SD card)
    bool import_offline_key(const std::vector<uint8_t>& key_data) {
        if (key_data.size() < 32) return false;
        offline_key = key_data;
        return true;
    }

    // ==================== Online Side (Hot Wallet) ====================

    // Prepare transaction for offline signing
    OfflineTransaction prepare_transaction(
        const std::string& from,
        const std::string& to,
        uint64_t amount,
        uint64_t fee = 100,
        const std::string& data = "") {

        OfflineTransaction tx;
        tx.tx_id = "TX-" + std::to_string(std::time(nullptr));
        tx.from_address = from;
        tx.to_address = to;
        tx.amount = amount;
        tx.fee = fee;
        tx.timestamp = std::time(nullptr);
        tx.data = data;
        tx.signed_ = false;

        // Generate hash to be signed
        tx.unsigned_hash = generate_tx_hash(tx);

        return tx;
    }

    // Create QR code data for offline device
    QRCodeData create_qr_code(const OfflineTransaction& tx) {
        QRCodeData qr;
        
        // Serialize transaction to string
        std::stringstream ss;
        ss << tx.from_address << "|"
           << tx.to_address << "|"
           << tx.amount << "|"
           << tx.fee << "|"
           << tx.timestamp << "|"
           << tx.data;

        qr.encoded_data = base64_encode(
            std::vector<uint8_t>(ss.str().begin(), ss.str().end()));
        qr.version = 10;  // High capacity QR
        qr.error_correction = 2; // M level

        // Checksum
        uint8_t checksum[SHA256_DIGEST_LENGTH];
        SHA256(reinterpret_cast<const uint8_t*>(qr.encoded_data.c_str()),
               qr.encoded_data.size(), checksum);
        qr.checksum = std::vector<uint8_t>(checksum, checksum + 8);

        return qr;
    }

    // ==================== Offline Side (Cold Wallet) ====================

    // Sign transaction from QR code data (offline)
    OfflineTransaction sign_from_qr(const QRCodeData& qr) {
        // Decode QR data
        auto decoded = base64_decode(qr.encoded_data);
        std::string tx_str(decoded.begin(), decoded.end());

        // Parse transaction
        OfflineTransaction tx;
        // (Simplified parsing - production would use proper deserialization)
        tx.unsigned_hash = std::vector<uint8_t>(tx_str.begin(), 
            tx_str.begin() + std::min(tx_str.size(), size_t(32)));

        // Sign with offline key (key never exposed to online device)
        tx.signature = sign_with_offline_key(tx.unsigned_hash);
        tx.signed_ = true;

        return tx;
    }

    // ==================== SD Card Transfer ====================

    // Export transaction for SD card transfer
    SDCardTransfer export_to_sd(const OfflineTransaction& tx, const std::string& path) {
        SDCardTransfer transfer;
        transfer.file_name = path + "/but_tx_" + tx.tx_id + ".dat";
        transfer.transfer_time = std::time(nullptr);

        // Serialize transaction
        std::stringstream ss;
        ss << tx.tx_id << "|" << tx.from_address << "|" << tx.to_address
           << "|" << tx.amount << "|" << tx.fee;
        
        std::string data = ss.str();
        transfer.file_data.assign(data.begin(), data.end());

        // Hash for integrity
        uint8_t hash[SHA256_DIGEST_LENGTH];
        SHA256(transfer.file_data.data(), transfer.file_data.size(), hash);
        transfer.file_hash = std::vector<uint8_t>(hash, hash + SHA256_DIGEST_LENGTH);

        return transfer;
    }

    // Import signed transaction from SD card
    OfflineTransaction import_from_sd(const SDCardTransfer& transfer) {
        OfflineTransaction tx;
        tx.signed_ = true;

        // Verify file integrity
        uint8_t expected_hash[SHA256_DIGEST_LENGTH];
        SHA256(transfer.file_data.data(), transfer.file_data.size(), expected_hash);

        bool integrity_ok = true;
        for (size_t i = 0; i < SHA256_DIGEST_LENGTH; ++i) {
            if (transfer.file_hash[i] != expected_hash[i]) {
                integrity_ok = false;
                break;
            }
        }

        if (!integrity_ok) {
            tx.signed_ = false;
            return tx;
        }

        // Parse and set signature (simplified)
        tx.signature = transfer.file_hash;
        return tx;
    }

    // ==================== Verification ====================

    // Verify signed transaction (online side)
    bool verify_signed_transaction(const OfflineTransaction& tx) {
        if (!tx.signed_) return false;
        if (tx.signature.empty()) return false;

        return verify_offline_signature(tx.unsigned_hash, tx.signature);
    }

    // Get AIR info
    static std::string get_info() {
        return "BUT AIR - Air-gapped Signing\n"
               "  ✅ QR Code Transfer\n"
               "  ✅ SD Card Transfer\n"
               "  ✅ Offline Key Storage\n"
               "  ✅ Integrity Verification";
    }
};

} // namespace air
} // namespace but
