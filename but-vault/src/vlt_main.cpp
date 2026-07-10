// BUT Network VLT - MPC Key Sharding Engine
// Splits and recovers private keys using Shamir's Secret Sharing

#include <iostream>
#include <vector>
#include <string>
#include <iomanip>
#include "vlt_engine.hpp"

using namespace but::vlt;

void print_hex(const std::string& label, const std::vector<uint8_t>& data) {
    std::cout << label << ": ";
    for (size_t i = 0; i < std::min(data.size(), size_t(16)); ++i) {
        std::cout << std::hex << std::setw(2) << std::setfill('0') << (int)data[i];
    }
    if (data.size() > 16) std::cout << "...";
    std::cout << std::dec << std::endl;
}

int main() {
    std::cout << "=== BUT VLT - MPC Key Sharding ===\n" << std::endl;

    // Create a test private key (64 bytes = 512-bit)
    std::vector<uint8_t> private_key(64);
    RAND_bytes(private_key.data(), private_key.size());
    
    print_hex("Original Private Key", private_key);
    std::cout << "Key Size: " << private_key.size() << " bytes (" 
              << private_key.size() * 8 << "-bit)\n" << std::endl;

    // Split into 5 shards
    std::cout << "--- Splitting Key into " << 5 << " Shards ---" << std::endl;
    auto shards = VLTEngine::split_key(private_key);

    for (const auto& shard : shards) {
        std::cout << VLTEngine::get_shard_info(shard) << std::endl;
        print_hex("  Data", shard.data);
    }

    // Verify all shards
    std::cout << "\n--- Verifying Shards ---" << std::endl;
    for (const auto& shard : shards) {
        bool valid = VLTEngine::verify_shard(shard);
        std::cout << "Shard #" << shard.index << ": " 
                  << (valid ? "VALID" : "INVALID") << std::endl;
    }

    // Recover with 3 shards
    std::cout << "\n--- Recovering Key with 3 Shards ---" << std::endl;
    std::vector<KeyShard> recovery_set = {shards[0], shards[2], shards[4]};
    auto recovered = VLTEngine::recover_key(recovery_set);

    if (!recovered.empty()) {
        print_hex("Recovered Key", recovered);
        bool match = (private_key == recovered);
        std::cout << "Match: " << (match ? "YES ✅" : "NO ❌") << std::endl;
    } else {
        std::cout << "Recovery FAILED!" << std::endl;
    }

    // Try with only 2 shards (should fail)
    std::cout << "\n--- Attempting Recovery with 2 Shards ---" << std::endl;
    std::vector<KeyShard> insufficient = {shards[0], shards[1]};
    auto failed = VLTEngine::recover_key(insufficient);

    if (failed.empty()) {
        std::cout << "Correctly rejected: Need minimum 3 shards ✅" << std::endl;
    }

    std::cout << "\n=== VLT Test Complete ===" << std::endl;
    return 0;
}
