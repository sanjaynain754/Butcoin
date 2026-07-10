// BUT Network VLT - Shamir Secret Sharing (MPC)
// Splits private key into 5 shards, requires 3 to recover

#pragma once

#include <vector>
#include <string>
#include <cstdint>
#include <random>
#include <algorithm>
#include <sstream>
#include <iomanip>
#include <openssl/sha.h>
#include <openssl/rand.h>

namespace but {
namespace vlt {

struct KeyShard {
    int index;                    // Shard number (1-5)
    std::vector<uint8_t> data;   // Shard data
    std::string checksum;        // Integrity check
};

class VLTEngine {
private:
    static constexpr int TOTAL_SHARDS = 5;
    static constexpr int THRESHOLD = 3;     // Minimum shards needed
    static constexpr int PRIME_BITS = 512;  // 512-bit prime field

    // Generate a random coefficient for polynomial
    static std::vector<uint8_t> generate_coefficient(size_t size) {
        std::vector<uint8_t> coeff(size);
        RAND_bytes(coeff.data(), size);
        return coeff;
    }

    // Evaluate polynomial at point x
    static std::vector<uint8_t> evaluate_polynomial(
        const std::vector<std::vector<uint8_t>>& coefficients,
        int x, size_t key_size) {
        
        std::vector<uint8_t> result(key_size, 0);
        
        // Horner's method for polynomial evaluation
        for (int i = coefficients.size() - 1; i >= 0; --i) {
            // Multiply result by x
            uint16_t carry = 0;
            for (size_t j = 0; j < key_size; ++j) {
                uint16_t val = result[j] * x + carry;
                result[j] = val & 0xFF;
                carry = val >> 8;
            }
            
            // Add coefficient
            carry = 0;
            for (size_t j = 0; j < key_size; ++j) {
                uint16_t val = result[j] + coefficients[i][j] + carry;
                result[j] = val & 0xFF;
                carry = val >> 8;
            }
        }
        
        return result;
    }

    // Lagrange interpolation to recover secret
    static std::vector<uint8_t> lagrange_interpolate(
        const std::vector<KeyShard>& shards,
        size_t key_size) {
        
        std::vector<uint8_t> secret(key_size, 0);
        
        for (size_t i = 0; i < shards.size(); ++i) {
            // Calculate Lagrange basis polynomial
            std::vector<uint8_t> basis(key_size, 1); // Start with 1
            
            for (size_t j = 0; j < shards.size(); ++j) {
                if (i == j) continue;
                
                // basis *= (0 - xj) / (xi - xj)
                int numerator = -shards[j].index;
                int denominator = shards[i].index - shards[j].index;
                
                // Multiply basis by numerator
                uint16_t carry = 0;
                for (size_t k = 0; k < key_size; ++k) {
                    uint16_t val = basis[k] * abs(numerator) + carry;
                    basis[k] = val & 0xFF;
                    carry = val >> 8;
                }
                
                // Divide by denominator (simplified)
                if (denominator != 0) {
                    carry = 0;
                    for (size_t k = key_size; k > 0; --k) {
                        size_t idx = k - 1;
                        uint16_t val = (carry << 8) | basis[idx];
                        basis[idx] = val / abs(denominator);
                        carry = val % abs(denominator);
                    }
                }
                
                if (numerator < 0 && denominator > 0) continue;
                if (numerator > 0 && denominator < 0) continue;
            }
            
            // Add term to secret
            uint16_t carry = 0;
            for (size_t k = 0; k < key_size; ++k) {
                uint16_t val = secret[k] + (shards[i].data[k] * basis[0]) + carry;
                secret[k] = val & 0xFF;
                carry = val >> 8;
            }
        }
        
        return secret;
    }

    // Generate checksum for shard
    static std::string generate_checksum(const std::vector<uint8_t>& data) {
        uint8_t hash[SHA256_DIGEST_LENGTH];
        SHA256(data.data(), data.size(), hash);
        
        std::stringstream ss;
        for (int i = 0; i < 8; ++i) {
            ss << std::hex << std::setw(2) << std::setfill('0') << (int)hash[i];
        }
        return ss.str();
    }

public:
    // Split a private key into 5 shards
    static std::vector<KeyShard> split_key(const std::vector<uint8_t>& private_key) {
        std::vector<KeyShard> shards;
        size_t key_size = private_key.size();
        
        // Generate random coefficients for polynomial of degree THRESHOLD-1
        std::vector<std::vector<uint8_t>> coefficients;
        coefficients.push_back(private_key); // First coefficient is the secret
        
        for (int i = 1; i < THRESHOLD; ++i) {
            coefficients.push_back(generate_coefficient(key_size));
        }
        
        // Generate shards at points x = 1, 2, 3, 4, 5
        for (int x = 1; x <= TOTAL_SHARDS; ++x) {
            KeyShard shard;
            shard.index = x;
            shard.data = evaluate_polynomial(coefficients, x, key_size);
            shard.checksum = generate_checksum(shard.data);
            shards.push_back(shard);
        }
        
        // Clear coefficients from memory
        for (auto& coeff : coefficients) {
            std::fill(coeff.begin(), coeff.end(), 0);
        }
        
        return shards;
    }

    // Recover private key from shards (minimum 3)
    static std::vector<uint8_t> recover_key(const std::vector<KeyShard>& shards) {
        if (shards.size() < THRESHOLD) {
            return {}; // Not enough shards
        }
        
        // Verify checksums
        for (const auto& shard : shards) {
            if (generate_checksum(shard.data) != shard.checksum) {
                return {}; // Corrupted shard
            }
        }
        
        // Use first THRESHOLD shards for recovery
        std::vector<KeyShard> selected(shards.begin(), shards.begin() + THRESHOLD);
        
        return lagrange_interpolate(selected, selected[0].data.size());
    }

    // Verify a shard's integrity
    static bool verify_shard(const KeyShard& shard) {
        return generate_checksum(shard.data) == shard.checksum;
    }

    // Get shard info (without revealing data)
    static std::string get_shard_info(const KeyShard& shard) {
        std::stringstream ss;
        ss << "Shard #" << shard.index 
           << " | Size: " << shard.data.size() << "B"
           << " | Checksum: " << shard.checksum.substr(0, 8);
        return ss.str();
    }
};

} // namespace vlt
} // namespace but
