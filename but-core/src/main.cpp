// BUT Network - Core Node Service
// Main entry point for the blockchain node

#include <iostream>
#include <csignal>
#include <atomic>
#include <thread>
#include <chrono>
#include "block.hpp"
#include "merkle.hpp"

using namespace but::core;

std::atomic<bool> running{true};

void signal_handler(int signal) {
    std::cout << "\n[*] Shutdown signal received: " << signal << std::endl;
    running = false;
}

void print_banner() {
    std::cout << R"(
╔══════════════════════════════════════════╗
║     BUT Network - Core Node v0.1.0       ║
║   Blockchain Universe Technology         ║
║   Quantum-Resistant | 512/1024-bit       ║
╚══════════════════════════════════════════╝
)" << std::endl;
}

int main() {
    // Setup signal handlers
    std::signal(SIGINT, signal_handler);
    std::signal(SIGTERM, signal_handler);

    print_banner();

    std::cout << "[+] Initializing chain manager..." << std::endl;
    ChainManager chain;

    std::cout << "[+] Genesis block created" << std::endl;
    std::cout << "    Height: " << chain.get_height() << std::endl;
    std::cout << "    Hash: " << chain.get_latest_block().compute_hash().substr(0, 32) << "..." << std::endl;

    // Create a test transaction
    std::cout << "\n[+] Creating test transaction..." << std::endl;
    SignalFragment tx;
    tx.source = "0xBUT-S-ALICE";
    tx.destination = "but://bob";
    tx.amount = 100000;
    tx.timestamp = std::chrono::system_clock::now().time_since_epoch().count();
    tx.sec_level = SecurityLevel::STANDARD_512;
    tx.fragment_id = tx.compute_id();

    std::cout << "    TX ID: " << tx.fragment_id.substr(0, 32) << "..." << std::endl;
    std::cout << "    Valid: " << (tx.validate() ? "YES" : "NO") << std::endl;

    // Build a block with transaction
    std::cout << "\n[+] Building test block..." << std::endl;
    DataSegment block;
    block.previous_hash = chain.get_latest_block().compute_hash();
    block.timestamp = std::chrono::system_clock::now().time_since_epoch().count();
    block.height = chain.get_height() + 1;
    block.fragments.push_back(tx);
    block.sec_level = SecurityLevel::STANDARD_512;
    block.nonce = 0;

    // Compute Merkle root
    QuantumMerkleTree tree(SecurityLevel::STANDARD_512);
    tree.build(block.fragments);
    block.merkle_root = tree.get_root();
    block.segment_id = block.compute_hash();

    std::cout << "    Merkle Root: " << block.merkle_root.substr(0, 32) << "..." << std::endl;
    std::cout << "    Block Hash: " << block.segment_id.substr(0, 32) << "..." << std::endl;

    // Add block to chain
    if (chain.add_block(block)) {
        std::cout << "[+] Block added successfully!" << std::endl;
        std::cout << "    New Height: " << chain.get_height() << std::endl;
    } else {
        std::cout << "[-] Block validation failed!" << std::endl;
    }

    // Validate chain
    std::cout << "\n[+] Chain validation: " 
              << (chain.validate_chain() ? "VALID" : "INVALID") << std::endl;

    // Keep node running
    std::cout << "\n[*] Node running. Press Ctrl+C to stop." << std::endl;
    while (running) {
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }

    std::cout << "[*] Node shut down gracefully." << std::endl;
    return 0;
}
