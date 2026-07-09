// BUT Network - Proof-of-Connection Consensus Engine
// Green mining: rewards based on network connectivity, not power waste

#pragma once

#include <string>
#include <vector>
#include <map>
#include <random>
#include <chrono>
#include <algorithm>
#include <openssl/sha.h>

namespace but {
namespace consensus {

// ==================== Connection Proof ====================

struct ConnectionProof {
    std::string node_id;
    std::string ip_address;
    int64_t     first_seen;       // Unix timestamp
    int64_t     last_heartbeat;   // Last activity
    uint32_t    uptime_seconds;   // Total connected time
    uint32_t    reputation;       // 0-1000 score
    uint32_t    blocks_validated; // Number of blocks validated
    std::string device_fingerprint; // Unique device ID (hashed)
};

class ProofOfConnection {
private:
    std::map<std::string, ConnectionProof> nodes;
    std::mt19937_64 rng;
    
    // Calculate connection score (0-1000)
    uint32_t calculate_score(const ConnectionProof& node) const {
        uint32_t score = 0;
        
        // Uptime factor (max 400 points)
        uint32_t uptime_days = node.uptime_seconds / 86400;
        score += std::min(uptime_days * 10, 400u);
        
        // Reputation factor (max 300 points)
        score += std::min(node.reputation * 3, 300u);
        
        // Blocks validated factor (max 200 points)
        score += std::min(node.blocks_validated * 5, 200u);
        
        // Recent activity bonus (max 100 points)
        int64_t now = std::chrono::system_clock::now().time_since_epoch().count();
        int64_t idle_seconds = (now - node.last_heartbeat) / 1'000'000'000;
        if (idle_seconds < 300) {
            score += 100;
        } else if (idle_seconds < 3600) {
            score += 50;
        }
        
        return std::min(score, 1000u);
    }

public:
    ProofOfConnection() {
        // Seed RNG with current time
        auto seed = std::chrono::system_clock::now().time_since_epoch().count();
        rng.seed(static_cast<uint64_t>(seed));
    }

    // Register a new node
    bool register_node(const std::string& node_id, const std::string& ip,
                       const std::string& device_info) {
        if (nodes.find(node_id) != nodes.end()) {
            return false; // Already registered
        }

        ConnectionProof proof;
        proof.node_id = node_id;
        proof.ip_address = ip;
        proof.first_seen = std::chrono::system_clock::now().time_since_epoch().count();
        proof.last_heartbeat = proof.first_seen;
        proof.uptime_seconds = 0;
        proof.reputation = 100; // Initial reputation
        proof.blocks_validated = 0;
        
        // Hash device fingerprint for privacy
        uint8_t hash[SHA512_DIGEST_LENGTH];
        SHA512(reinterpret_cast<const uint8_t*>(device_info.c_str()),
               device_info.size(), hash);
        proof.device_fingerprint = std::string(reinterpret_cast<char*>(hash), 16);

        nodes[node_id] = proof;
        return true;
    }

    // Update heartbeat (called periodically)
    void heartbeat(const std::string& node_id) {
        auto it = nodes.find(node_id);
        if (it == nodes.end()) return;

        auto& node = it->second;
        int64_t now = std::chrono::system_clock::now().time_since_epoch().count();
        int64_t elapsed = (now - node.last_heartbeat) / 1'000'000'000;
        
        if (elapsed > 0 && elapsed < 3600) {
            node.uptime_seconds += static_cast<uint32_t>(elapsed);
        }
        
        node.last_heartbeat = now;
    }

    // Select validator for next block
    std::string select_validator() {
        if (nodes.empty()) return "";

        // Calculate scores
        std::vector<std::pair<std::string, uint32_t>> candidates;
        for (const auto& [id, node] : nodes) {
            uint32_t score = calculate_score(node);
            if (score > 0) {
                candidates.push_back({id, score});
            }
        }

        if (candidates.empty()) return "";

        // Weighted random selection
        uint32_t total_score = 0;
        for (const auto& [_, score] : candidates) {
            total_score += score;
        }

        std::uniform_int_distribution<uint32_t> dist(0, total_score - 1);
        uint32_t target = dist(rng);
        
        uint32_t cumulative = 0;
        for (const auto& [id, score] : candidates) {
            cumulative += score;
            if (target < cumulative) {
                return id;
            }
        }

        return candidates.back().first;
    }

    // Reward validator after successful block
    void reward_validator(const std::string& node_id) {
        auto it = nodes.find(node_id);
        if (it == nodes.end()) return;

        auto& node = it->second;
        node.blocks_validated++;
        node.reputation = std::min(node.reputation + 5, 1000u);
    }

    // Penalize malicious validator
    void penalize_validator(const std::string& node_id) {
        auto it = nodes.find(node_id);
        if (it == nodes.end()) return;

        auto& node = it->second;
        node.reputation = std::max(node.reputation, 50u) - 50;
    }

    // Get top validators
    std::vector<std::pair<std::string, uint32_t>> get_top_validators(size_t count = 10) const {
        std::vector<std::pair<std::string, uint32_t>> ranked;
        for (const auto& [id, node] : nodes) {
            ranked.push_back({id, calculate_score(node)});
        }

        std::sort(ranked.begin(), ranked.end(),
                  [](const auto& a, const auto& b) { return a.second > b.second; });

        if (ranked.size() > count) {
            ranked.resize(count);
        }
        return ranked;
    }

    // Get node count
    size_t get_node_count() const {
        return nodes.size();
    }

    // Remove inactive nodes (no heartbeat for 7 days)
    void cleanup_inactive() {
        int64_t now = std::chrono::system_clock::now().time_since_epoch().count();
        
        for (auto it = nodes.begin(); it != nodes.end();) {
            int64_t idle = (now - it->second.last_heartbeat) / 1'000'000'000;
            if (idle > 604800) { // 7 days
                it = nodes.erase(it);
            } else {
                ++it;
            }
        }
    }
};

} // namespace consensus
} // namespace but
