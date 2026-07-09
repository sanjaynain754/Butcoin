// BUT Network - Consensus Node
// Proof-of-Connection green mining engine

#include <iostream>
#include <csignal>
#include <atomic>
#include <thread>
#include <chrono>
#include <iomanip>
#include "validator.hpp"

using namespace but::consensus;

std::atomic<bool> running{true};

void signal_handler(int signal) {
    std::cout << "\n[*] Consensus shutdown signal: " << signal << std::endl;
    running = false;
}

void print_banner() {
    std::cout << R"(
╔══════════════════════════════════════════╗
║   BUT Consensus - Proof-of-Connection   ║
║         Green Mining Engine             ║
║     Zero extra power consumption        ║
╚══════════════════════════════════════════╝
)" << std::endl;
}

int main() {
    std::signal(SIGINT, signal_handler);
    std::signal(SIGTERM, signal_handler);

    print_banner();

    ValidatorManager manager;

    // Register some test validators
    std::cout << "[+] Registering validators..." << std::endl;
    manager.register_validator("NODE-ALICE", "192.168.1.1", "mobile-samsung-a54");
    manager.register_validator("NODE-BOB", "192.168.1.2", "mobile-pixel-7");
    manager.register_validator("NODE-CHARLIE", "192.168.1.3", "mobile-oneplus-11");
    manager.register_validator("NODE-DIANA", "192.168.1.4", "mobile-iphone-15");

    std::cout << "[+] Starting mining simulation..." << std::endl;
    std::cout << "    (Each block = ~10 seconds for demo)\n" << std::endl;

    // Mining loop
    int blocks_mined = 0;
    while (running && blocks_mined < 20) {
        // Process heartbeats
        manager.process_heartbeat("NODE-ALICE");
        manager.process_heartbeat("NODE-BOB");
        manager.process_heartbeat("NODE-CHARLIE");
        manager.process_heartbeat("NODE-DIANA");

        // Mine block
        auto reward = manager.mine_block();

        if (reward.total_reward > 0) {
            auto stats = manager.get_stats();
            
            std::cout << "═══════════════════════════════════" << std::endl;
            std::cout << "Block #" << stats.block_count << " mined!" << std::endl;
            std::cout << "├─ Base Reward:    " << std::fixed << std::setprecision(2)
                      << reward.base_reward / 100'000'000.0 << " BUT" << std::endl;
            std::cout << "├─ Connection Bonus: " 
                      << reward.connection_bonus / 100'000'000.0 << " BUT" << std::endl;
            std::cout << "├─ Reputation Bonus: " 
                      << reward.reputation_bonus / 100'000'000.0 << " BUT" << std::endl;
            std::cout << "├─ Total Reward:   " 
                      << reward.total_reward / 100'000'000.0 << " BUT" << std::endl;
            std::cout << "├─ Active Nodes:   " << stats.active_validators << std::endl;
            std::cout << "├─ Total Supply:   " 
                      << stats.total_supply / 100'000'000.0 << " BUT" << std::endl;
            std::cout << "└─ Remaining:      " 
                      << stats.remaining_supply / 100'000'000.0 << " BUT" << std::endl;
            std::cout << "═══════════════════════════════════\n" << std::endl;
            
            blocks_mined++;
        }

        // Simulate block time
        std::this_thread::sleep_for(std::chrono::seconds(2));
    }

    // Final stats
    auto final_stats = manager.get_stats();
    std::cout << "\n[*] Mining session ended." << std::endl;
    std::cout << "[*] Total blocks: " << final_stats.block_count << std::endl;
    std::cout << "[*] Total supply: " << final_stats.total_supply / 100'000'000.0 << " BUT" << std::endl;

    return 0;
}
