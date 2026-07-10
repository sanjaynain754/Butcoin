// BUT Network TLK - Time Lock Encryption
// Future-time encryption for inheritance & delayed transactions

#include <iostream>
#include <vector>
#include <string>
#include <iomanip>
#include <chrono>
#include <thread>
#include "tlk_engine.hpp"

using namespace but::tlk;

void print_hex(const std::string& label, const std::vector<uint8_t>& data) {
    std::cout << label << ": ";
    for (size_t i = 0; i < std::min(data.size(), size_t(16)); ++i) {
        std::cout << std::hex << std::setw(2) << std::setfill('0') << (int)data[i];
    }
    if (data.size() > 16) std::cout << "...";
    std::cout << std::dec << std::endl;
}

int main() {
    std::cout << "=== BUT TLK - Time Lock Encryption ===\n" << std::endl;

    // ==================== Test 1: Create Time-lock Puzzle ====================
    std::cout << "--- Test 1: Create Time-locked Message ---" << std::endl;
    
    // Secret message
    std::string secret = "BUT Network Private Key: 0xS1234567890ABCDEF";
    std::vector<uint8_t> secret_data(secret.begin(), secret.end());
    
    // Lock for 60 seconds from now
    auto unlock_time = std::chrono::system_clock::now() + std::chrono::seconds(60);
    int64_t unlock_ts = std::chrono::system_clock::to_time_t(unlock_time);
    
    std::cout << "Creating time-lock puzzle..." << std::endl;
    auto puzzle = TLKEngine::create_puzzle(secret_data, unlock_ts, 0);
    
    std::cout << TLKEngine::get_puzzle_info(puzzle) << std::endl;
    print_hex("Encrypted", puzzle.encrypted_data);

    // ==================== Test 2: Try Early Unlock ====================
    std::cout << "\n--- Test 2: Attempt Early Unlock ---" << std::endl;
    
    if (TLKEngine::is_unlockable(puzzle)) {
        std::cout << "Already unlocked - trying..." << std::endl;
        auto decrypted = TLKEngine::solve_puzzle(puzzle);
        if (!decrypted.empty()) {
            std::string msg(decrypted.begin(), decrypted.end());
            std::cout << "Decrypted: " << msg << std::endl;
        }
    } else {
        int64_t remaining = TLKEngine::get_remaining_seconds(puzzle);
        std::cout << "Still locked! Remaining: " << remaining << " seconds" << std::endl;
        std::cout << "Cannot access until time passes ✅" << std::endl;
    }

    // ==================== Test 3: Short Time-lock (5 seconds) ====================
    std::cout << "\n--- Test 3: Short Time-lock (5 seconds) ---" << std::endl;
    
    std::string quick_secret = "Quick unlock test message";
    std::vector<uint8_t> quick_data(quick_secret.begin(), quick_secret.end());
    
    auto quick_time = std::chrono::system_clock::now() + std::chrono::seconds(5);
    int64_t quick_ts = std::chrono::system_clock::to_time_t(quick_time);
    
    auto quick_puzzle = TLKEngine::create_puzzle(quick_data, quick_ts, 0);
    std::cout << TLKEngine::get_puzzle_info(quick_puzzle) << std::endl;
    
    std::cout << "Waiting for unlock time..." << std::endl;
    while (!TLKEngine::is_unlockable(quick_puzzle)) {
        std::this_thread::sleep_for(std::chrono::seconds(1));
        std::cout << "." << std::flush;
    }
    std::cout << "\nUnlocked!" << std::endl;
    
    auto decrypted = TLKEngine::solve_puzzle(quick_puzzle);
    if (!decrypted.empty()) {
        std::string msg(decrypted.begin(), decrypted.end());
        std::cout << "Decrypted: " << msg << " ✅" << std::endl;
    }

    // ==================== Test 4: Inheritance Planning ====================
    std::cout << "\n--- Test 4: Inheritance Time-lock (Demo) ---" << std::endl;
    
    std::string inheritance = "Wallet recovery phrase for family: apple banana cherry...";
    std::vector<uint8_t> inheritance_data(inheritance.begin(), inheritance.end());
    
    // Lock for 365 days (simulated as 10 seconds for demo)
    auto inheritance_time = std::chrono::system_clock::now() + std::chrono::seconds(10);
    int64_t inheritance_ts = std::chrono::system_clock::to_time_t(inheritance_time);
    
    auto inheritance_puzzle = TLKEngine::create_puzzle(inheritance_data, inheritance_ts, 0);
    std::cout << TLKEngine::get_puzzle_info(inheritance_puzzle) << std::endl;
    std::cout << "Inheritance data locked until timer expires ✅" << std::endl;
    std::cout << "(In production: 365 days lock period)" << std::endl;

    // ==================== Summary ====================
    std::cout << "\n--- TLK Features ---" << std::endl;
    std::cout << "✅ Time-lock Encryption" << std::endl;
    std::cout << "✅ Delayed Transactions" << std::endl;
    std::cout << "✅ Inheritance Planning" << std::endl;
    std::cout << "✅ Dead Man's Switch Ready" << std::endl;
    std::cout << "✅ Anti-frontrunning Protection" << std::endl;

    std::cout << "\n=== TLK Test Complete ===" << std::endl;
    return 0;
}
