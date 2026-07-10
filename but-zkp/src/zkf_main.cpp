// BUT Network ZKF - Zero-Knowledge Flow Engine
// Proves knowledge of secret without revealing it

#include <iostream>
#include <vector>
#include <string>
#include <iomanip>
#include "zkf_engine.hpp"

using namespace but::zkf;

void print_hex(const std::string& label, const std::vector<uint8_t>& data) {
    std::cout << label << ": ";
    for (size_t i = 0; i < std::min(data.size(), size_t(16)); ++i) {
        std::cout << std::hex << std::setw(2) << std::setfill('0') << (int)data[i];
    }
    if (data.size() > 16) std::cout << "...";
    std::cout << std::dec << std::endl;
}

int main() {
    std::cout << "=== BUT ZKF - Zero-Knowledge Flow ===\n" << std::endl;

    // ==================== Test 1: Schnorr ZK Proof ====================
    std::cout << "--- Test 1: Schnorr Zero-Knowledge Proof ---" << std::endl;
    
    // Create a secret (e.g., private key)
    std::vector<uint8_t> secret(32);
    RAND_bytes(secret.data(), secret.size());
    print_hex("Secret (Private Key)", secret);
    
    // Create public key (hash of secret)
    uint8_t pk_hash[SHA512_DIGEST_LENGTH];
    SHA512(secret.data(), secret.size(), pk_hash);
    std::vector<uint8_t> public_key(pk_hash, pk_hash + 32);
    print_hex("Public Key", public_key);
    
    // Prover generates proof
    std::cout << "\n[Prover] Generating ZK proof..." << std::endl;
    auto proof = ZKFEngine::generate_proof(secret);
    std::cout << "Proof: " << ZKFEngine::proof_to_string(proof) << std::endl;
    
    // Verifier checks proof
    std::cout << "\n[Verifier] Checking proof..." << std::endl;
    bool valid = ZKFEngine::verify_proof(proof, public_key);
    std::cout << "Result: " << (valid ? "VALID ✅" : "INVALID ❌") << std::endl;
    
    // Tampered proof test
    std::cout << "\n--- Tampered Proof Test ---" << std::endl;
    auto tampered = proof;
    tampered.response[0] ^= 0xFF; // Modify response
    bool tampered_valid = ZKFEngine::verify_proof(tampered, public_key);
    std::cout << "Tampered Result: " << (tampered_valid ? "VALID ❌" : "INVALID ✅") << std::endl;

    // ==================== Test 2: Range Proof ====================
    std::cout << "\n--- Test 2: Range Proof (Bulletproofs-style) ---" << std::endl;
    
    uint64_t balance = 500000; // 500 BUT in Bites
    std::cout << "Balance: " << balance << " Bites" << std::endl;
    
    // Prove balance is positive without revealing exact amount
    auto range_proof = ZKFEngine::generate_range_proof(balance, 64);
    std::cout << "Range Proof generated" << std::endl;
    
    // Verify range
    uint64_t max_allowed = 21000000000; // 21M BUT supply cap
    bool range_valid = ZKFEngine::verify_range_proof(range_proof, max_allowed);
    std::cout << "Range Valid: " << (range_valid ? "YES ✅" : "NO ❌") << std::endl;
    
    // Test with value out of range
    uint64_t invalid_value = 22000000000; // Above supply cap
    bool range_invalid = ZKFEngine::verify_range_proof(range_proof, invalid_value);
    std::cout << "Out-of-Range Check: " << (range_invalid ? "PASS ❌" : "BLOCKED ✅") << std::endl;

    std::cout << "\n=== ZKF Test Complete ===" << std::endl;
    return 0;
}
