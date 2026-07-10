// BUT Network AIS - AI Shield Engine
// Behavior Analysis & Threat Detection

#include <iostream>
#include <vector>
#include <string>
#include <iomanip>
#include "ais_engine.hpp"

using namespace but::ais;

std::string action_to_string(AISEngine::Action action) {
    switch (action) {
        case AISEngine::Action::ALLOW: return "ALLOW ✅";
        case AISEngine::Action::FLAG:  return "FLAG ⚠️";
        case AISEngine::Action::DELAY: return "DELAY ⏳";
        case AISEngine::Action::BLOCK: return "BLOCK 🚫";
    }
    return "UNKNOWN";
}

int main() {
    std::cout << "=== BUT AIS - AI Shield ===\n" << std::endl;

    AISEngine engine;

    // ==================== Test 1: Normal Transactions ====================
    std::cout << "--- Test 1: Normal User Behavior ---" << std::endl;
    
    std::vector<TxProfile> normal_txs;
    for (int i = 0; i < 5; i++) {
        TxProfile tx;
        tx.sender = "0xALICE";
        tx.receiver = "0xBOB";
        tx.amount = 10000 + (i * 5000); // 10-30 BUT
        tx.timestamp = 1000000 + (i * 600); // Every 10 minutes
        tx.tx_type = "transfer";
        
        engine.learn_from_transaction(tx);
        auto decision = engine.evaluate_transaction(tx);
        
        std::cout << "TX #" << (i+1) 
                  << " | Amount: " << tx.amount << " Bites"
                  << " | Risk: " << std::fixed << std::setprecision(2) << decision.risk_score
                  << " | " << action_to_string(decision.action) << std::endl;
    }
    
    std::cout << "Pattern: " << engine.get_pattern_info("0xALICE") << std::endl;

    // ==================== Test 2: Suspicious Activity ====================
    std::cout << "\n--- Test 2: Rapid Fire Attack ---" << std::endl;
    
    for (int i = 0; i < 15; i++) {
        TxProfile tx;
        tx.sender = "0xHACKER";
        tx.receiver = "0xVICTIM" + std::to_string(i);
        tx.amount = 500000; // 500 BUT
        tx.timestamp = 2000000 + (i * 2); // Every 2 seconds!
        tx.tx_type = "transfer";
        
        engine.learn_from_transaction(tx);
        auto decision = engine.evaluate_transaction(tx);
        
        if (i < 3 || decision.action != AISEngine::Action::ALLOW) {
            std::cout << "TX #" << (i+1) 
                      << " | Amount: " << tx.amount << " Bites"
                      << " | Risk: " << std::fixed << std::setprecision(2) << decision.risk_score
                      << " | " << action_to_string(decision.action)
                      << " | " << decision.reason << std::endl;
        }
    }

    // ==================== Test 3: Dust Attack ====================
    std::cout << "\n--- Test 3: Dust Attack Detection ---" << std::endl;
    
    for (int i = 0; i < 3; i++) {
        TxProfile tx;
        tx.sender = "0xDUSTER";
        tx.receiver = "0xTARGET";
        tx.amount = 50; // Very small amount (0.05 BUT)
        tx.timestamp = 3000000 + (i * 30);
        tx.tx_type = "transfer";
        
        engine.learn_from_transaction(tx);
        auto decision = engine.evaluate_transaction(tx);
        
        std::cout << "TX #" << (i+1) 
                  << " | Amount: " << tx.amount << " Bites"
                  << " | Risk: " << std::fixed << std::setprecision(2) << decision.risk_score
                  << " | " << action_to_string(decision.action)
                  << " | " << decision.reason << std::endl;
    }

    // ==================== Test 4: Large Unknown Transaction ====================
    std::cout << "\n--- Test 4: Large Unknown Transaction ---" << std::endl;
    
    TxProfile large_tx;
    large_tx.sender = "0xUNKNOWN";
    large_tx.receiver = "0xEXCHANGE";
    large_tx.amount = 5000000; // 5000 BUT - very large
    large_tx.timestamp = 4000000;
    large_tx.tx_type = "transfer";
    
    engine.learn_from_transaction(large_tx);
    auto decision = engine.evaluate_transaction(large_tx);
    
    std::cout << "Amount: " << large_tx.amount << " Bites"
              << " | Risk: " << std::fixed << std::setprecision(2) << decision.risk_score
              << " | " << action_to_string(decision.action)
              << " | " << decision.reason << std::endl;

    // ==================== Final Report ====================
    std::cout << "\n--- Security Report ---" << std::endl;
    auto report = engine.generate_report();
    
    std::cout << "Total Analyzed: " << report.total_analyzed << std::endl;
    std::cout << "Allowed: " << report.allowed << std::endl;
    std::cout << "Flagged: " << report.flagged << std::endl;
    std::cout << "Delayed: " << report.delayed << std::endl;
    std::cout << "Blocked: " << report.blocked << std::endl;
    std::cout << "Avg Risk: " << std::fixed << std::setprecision(3) << report.avg_risk_score << std::endl;

    std::cout << "\n=== AIS Test Complete ===" << std::endl;
    return 0;
}
