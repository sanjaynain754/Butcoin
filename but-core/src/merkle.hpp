// BUT Network - Quantum-Resistant Merkle Tree
// Uses SHA-512/1024 for collision resistance against quantum attacks

#pragma once

#include "block.hpp"
#include <vector>
#include <string>
#include <algorithm>
#include <cmath>

namespace but {
namespace core {

class QuantumMerkleTree {
private:
    std::vector<std::string> leaves;
    std::vector<std::vector<std::string>> levels;
    SecurityLevel sec_level;

    // Compute parent hash from two children
    std::string compute_parent(const std::string& left, const std::string& right) const {
        std::string combined = left + right;
        if (sec_level == SecurityLevel::VAULT_1024) {
            return double_sha512_hex(combined);
        }
        return sha512_hex(combined);
    }

public:
    QuantumMerkleTree(SecurityLevel level = SecurityLevel::STANDARD_512)
        : sec_level(level) {}

    // Build tree from transaction data
    void build(const std::vector<SignalFragment>& fragments) {
        leaves.clear();
        levels.clear();

        // Create leaf hashes from transactions
        for (const auto& frag : fragments) {
            std::string leaf_data = frag.compute_id();
            if (sec_level == SecurityLevel::VAULT_1024) {
                leaves.push_back(double_sha512_hex(leaf_data));
            } else {
                leaves.push_back(sha512_hex(leaf_data));
            }
        }

        // If odd number of leaves, duplicate last
        if (leaves.size() % 2 != 0 && !leaves.empty()) {
            leaves.push_back(leaves.back());
        }

        // Build tree levels
        levels.push_back(leaves);
        auto current_level = leaves;

        while (current_level.size() > 1) {
            std::vector<std::string> next_level;
            for (size_t i = 0; i < current_level.size(); i += 2) {
                if (i + 1 < current_level.size()) {
                    next_level.push_back(compute_parent(current_level[i], current_level[i + 1]));
                } else {
                    next_level.push_back(current_level[i]);
                }
            }
            levels.push_back(next_level);
            current_level = next_level;
        }
    }

    // Get Merkle root
    std::string get_root() const {
        if (levels.empty()) return "";
        return levels.back().front();
    }

    // Generate proof for a specific transaction index
    std::vector<std::string> generate_proof(size_t index) const {
        std::vector<std::string> proof;
        if (index >= leaves.size()) return proof;

        size_t current_index = index;
        for (size_t level = 0; level < levels.size() - 1; ++level) {
            const auto& current_level = levels[level];
            size_t sibling_index = (current_index % 2 == 0) ? current_index + 1 : current_index - 1;

            if (sibling_index < current_level.size()) {
                std::string direction = (current_index % 2 == 0) ? "R:" : "L:";
                proof.push_back(direction + current_level[sibling_index]);
            }
            current_index /= 2;
        }
        return proof;
    }

    // Verify a proof
    bool verify_proof(const std::string& leaf, const std::vector<std::string>& proof,
                      const std::string& expected_root) const {
        std::string current = leaf;

        for (const auto& p : proof) {
            bool is_right_sibling = (p.substr(0, 2) == "R:");
            std::string sibling_hash = p.substr(2);

            if (is_right_sibling) {
                current = compute_parent(current, sibling_hash);
            } else {
                current = compute_parent(sibling_hash, current);
            }
        }

        return current == expected_root;
    }

    // Get tree statistics
    size_t get_leaf_count() const { return leaves.size(); }
    size_t get_depth() const { return levels.size(); }
};

// ==================== Chain Manager ====================

class ChainManager {
private:
    std::vector<DataSegment> chain;
    std::string chain_id;

public:
    ChainManager() {
        // Initialize with genesis block
        chain.push_back(create_genesis_block());
        chain_id = "BUT-MAIN-CHAIN";
    }

    // Add a new block after validation
    bool add_block(const DataSegment& block) {
        // Validate block links to previous
        const auto& prev = chain.back();
        if (block.previous_hash != prev.compute_hash()) {
            return false;
        }

        // Validate block height
        if (block.height != prev.height + 1) {
            return false;
        }

        // Validate merkle root
        QuantumMerkleTree tree(block.sec_level);
        tree.build(block.fragments);
        if (tree.get_root() != block.merkle_root) {
            return false;
        }

        chain.push_back(block);
        return true;
    }

    // Get chain height
    uint64_t get_height() const {
        return chain.back().height;
    }

    // Get block by height
    const DataSegment* get_block(uint64_t height) const {
        if (height < chain.size()) {
            return &chain[height];
        }
        return nullptr;
    }

    // Get latest block
    const DataSegment& get_latest_block() const {
        return chain.back();
    }

    // Validate entire chain
    bool validate_chain() const {
        for (size_t i = 1; i < chain.size(); ++i) {
            const auto& curr = chain[i];
            const auto& prev = chain[i - 1];

            // Check hash link
            if (curr.previous_hash != prev.compute_hash()) {
                return false;
            }

            // Check height
            if (curr.height != prev.height + 1) {
                return false;
            }
        }
        return true;
    }
};

} // namespace core
} // namespace but
