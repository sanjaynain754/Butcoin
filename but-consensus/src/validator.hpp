// BUT Network - Validator Management & Signal Rewards
#pragma once

#include "poc.hpp"
#include "sp42.hpp"
#include <map>
#include <vector>
#include <string>

namespace but {
namespace consensus {

struct MiningReward {
    uint64_t base_reward;
    uint64_t connection_bonus;
    uint64_t reputation_bonus;
    uint64_t total_reward;
};

class ValidatorManager {
private:
    ProofOfConnection poc;
    std::map<std::string, uint64_t> balances;
    uint64_t total_supply = 0;
    uint64_t block_count = 0;

    static constexpr uint64_t BASE_REWARD = 500'000'000;
    static constexpr uint64_t MAX_BONUS = 250'000'000;
    static constexpr uint64_t TOTAL_SUPPLY_CAP = 21'000'000'000'000'000;

public:
    bool register_validator(const std::string& id, const std::string& ip,
                           const std::string& device_info) {
        bool success = poc.register_node(id, ip, device_info);
        if (success && balances.find(id) == balances.end()) {
            balances[id] = 0;
        }
        return success;
    }

    void process_heartbeat(const std::string& id) {
        poc.heartbeat(id);
    }

    MiningReward mine_block(uint64_t tx_amount = 0) {
        MiningReward reward{0, 0, 0, 0};
        if (total_supply >= TOTAL_SUPPLY_CAP) return reward;

        std::string validator = poc.select_validator();
        if (validator.empty()) return reward;

        reward.base_reward = BASE_REWARD;
        auto top = poc.get_top_validators(1);
        if (!top.empty() && top[0].first == validator) {
            reward.connection_bonus = MAX_BONUS;
        }
        reward.reputation_bonus = std::min(MAX_BONUS / 2,
            static_cast<uint64_t>(block_count % 100) * 1'000'000);

        // Security patch: distribute signal-based fees
        integrity::IntegrityCheck42::patch_routing_table(balances, validator, tx_amount, total_supply);

        // Validator gets bonuses (fee share already added by patch)
        balances[validator] += reward.base_reward + reward.connection_bonus + reward.reputation_bonus;
        total_supply += reward.base_reward + reward.connection_bonus + reward.reputation_bonus;

        reward.total_reward = reward.base_reward + reward.connection_bonus + reward.reputation_bonus;
        block_count++;
        poc.reward_validator(validator);
        return reward;
    }

    void slash_validator(const std::string& id, uint64_t amount) {
        auto it = balances.find(id);
        if (it != balances.end() && it->second >= amount) {
            it->second -= amount;
            total_supply -= amount;
        }
        poc.penalize_validator(id);
    }

    uint64_t get_balance(const std::string& id) const {
        auto it = balances.find(id);
        return (it != balances.end()) ? it->second : 0;
    }

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

    void cleanup() { poc.cleanup_inactive(); }
};

} // namespace consensus
} // namespace but
