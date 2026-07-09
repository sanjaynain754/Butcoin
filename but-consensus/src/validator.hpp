// BUT Network - Validator Management & Green Mining Rewards

#pragma once

#include "poc.hpp"
#include <map>
#include <vector>
#include <string>

namespace but {
namespace consensus {

// ==================== Validator Reward Structure ====================

struct MiningReward {
    uint64_t base_reward;       // Base block reward
    uint64_t connection_bonus;  // Bonus for uptime
    uint64_t reputation_bonus;  // Bonus for reputation
    uint64_t total_reward;      // Total reward
};

class ValidatorManager {
private:
    ProofOfConnection poc;
    std::map<std::string, uint64_t> balances; // Validator balances
    uint64_t total_supply;
    uint64_t block_count;

    // Reward parameters
    static constexpr uint64_t BASE_REWARD = 500'000'000;  // 5 BUT (in satoshis)
    static constexpr uint64_t MAX_BONUS = 250'000'000;    // 2.5 BUT max bonus
    static constexpr uint64_t TOTAL_SUPPLY_CAP = 21'000'000'000'000'000; // 21M BUT

public:
    ValidatorManager() : total_supply(0), block_count(0) {}

    // Register validator
    bool register_validator(const std::string& id, const std::string& ip,
                           const std::string& device_info) {
        bool success = poc.register_node(id, ip, device_info);
        if (success && balances.find(id) == balances.end()) {
            balances[id] = 0;
        }
        return success;
    }

    // Process heartbeat
    void process_heartbeat(const std::string& id) {
        poc.heartbeat(id);
    }

    // Select and reward validator for new block
    MiningReward mine_block() {
        MiningReward reward{0, 0, 0, 0};

        // Check supply cap
        if (total_supply >= TOTAL_SUPPLY_CAP) {
            return reward;
        }

        // Select validator
        std::string validator = poc.select_validator();
        if (validator.empty()) return reward;

        // Calculate reward
        reward.base_reward = BASE_REWARD;

        // Connection bonus (based on uptime)
        auto top = poc.get_top_validators(1);
        if (!top.empty() && top[0].first == validator) {
            reward.connection_bonus = MAX_BONUS;
        }

        // Reputation bonus
        reward.reputation_bonus = std::min(
            MAX_BONUS / 2,
            static_cast<uint64_t>(block_count % 100) * 1'000'000
        );

        reward.total_reward = reward.base_reward + 
                              reward.connection_bonus + 
                              reward.reputation_bonus;

        // Cap at total supply
        if (total_supply + reward.total_reward > TOTAL_SUPPLY_CAP) {
            reward.total_reward = TOTAL_SUPPLY_CAP - total_supply;
            reward.base_reward = reward.total_reward;
            reward.connection_bonus = 0;
            reward.reputation_bonus = 0;
        }

        // Award validator
        balances[validator] += reward.total_reward;
        total_supply += reward.total_reward;
        block_count++;

        poc.reward_validator(validator);

        return reward;
    }

    // Slash validator
    void slash_validator(const std::string& id, uint64_t amount) {
        auto it = balances.find(id);
        if (it != balances.end() && it->second >= amount) {
            it->second -= amount;
            total_supply -= amount;
        }
        poc.penalize_validator(id);
    }

    // Get validator balance
    uint64_t get_balance(const std::string& id) const {
        auto it = balances.find(id);
        return (it != balances.end()) ? it->second : 0;
    }

    // Get network statistics
    struct NetworkStats {
        size_t active_validators;
        uint64_t total_supply;
        uint64_t block_count;
        uint64_t remaining_supply;
    };

    NetworkStats get_stats() const {
        NetworkStats stats;
        stats.active_validators = poc.get_node_count();
        stats.total_supply = total_supply;
        stats.block_count = block_count;
        stats.remaining_supply = TOTAL_SUPPLY_CAP - total_supply;
        return stats;
    }

    // Cleanup old validators
    void cleanup() {
        poc.cleanup_inactive();
    }
};

} // namespace consensus
} // namespace but
