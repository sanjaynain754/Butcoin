// ==================== BUT Currency Constants ====================

constexpr uint64_t BITES_PER_BUT = 1000;           // 1 BUT = 1000 Bites
constexpr uint64_t TOTAL_BUT_SUPPLY = 21'000'000;  // 21 Million BUT
constexpr uint64_t TOTAL_BITES_SUPPLY = TOTAL_BUT_SUPPLY * BITES_PER_BUT; // 21 Billion Bites

// ==================== Fee Structure ====================

enum class TransactionType : uint8_t {
    STANDARD_TRANSFER  = 0x01,  // Normal send
    VAULT_TRANSFER     = 0x02,  // 1024-bit secure send
    CONTRACT_EXECUTION = 0x03,  // Smart contract
    NAME_REGISTRATION  = 0x04,  // but://username
    SOCIAL_RECOVERY    = 0x05   // Recovery request
};

struct FeeCalculator {
    static uint64_t calculate_fee(TransactionType type, uint64_t amount_bites) {
        // Base fee in Bites
        uint64_t base_fee = 1; // Minimum 1 Bite

        switch (type) {
            case TransactionType::STANDARD_TRANSFER:
                base_fee = 1; // 1 Bite = 0.001 BUT
                // Add 0.1% of amount (min 1 Bite)
                return std::max(base_fee, amount_bites / 1000);

            case TransactionType::VAULT_TRANSFER:
                base_fee = 5; // 5 Bites = 0.005 BUT
                return std::max(base_fee, amount_bites / 500);

            case TransactionType::CONTRACT_EXECUTION:
                base_fee = 10;
                return base_fee + (amount_bites / 200);

            case TransactionType::NAME_REGISTRATION:
                return 50; // Flat 50 Bites = 0.05 BUT

            case TransactionType::SOCIAL_RECOVERY:
                return 100; // Flat 100 Bites = 0.1 BUT

            default:
                return base_fee;
        }
    }
};

// Update SignalFragment struct
struct SignalFragment {
    std::string fragment_id;
    std::string source;
    std::string destination;
    uint64_t    amount;           // Amount in BITES (not BUT)
    uint64_t    fee;              // Fee in BITES
    int64_t     timestamp;
    std::vector<uint8_t> signature;
    SecurityLevel sec_level;
    TransactionType tx_type;      // 🆕 Transaction type
    std::string data_hash;

    // Get amount in BUT (for display)
    double amount_in_but() const {
        return static_cast<double>(amount) / BITES_PER_BUT;
    }

    // Get fee in BUT (for display)
    double fee_in_but() const {
        return static_cast<double>(fee) / BITES_PER_BUT;
    }

    // Total cost = amount + fee (in Bites)
    uint64_t total_cost_bites() const {
        return amount + fee;
    }

    // Generate transaction ID
    std::string compute_id() const {
        std::stringstream ss;
        ss << source << destination << amount << fee << timestamp;
        if (sec_level == SecurityLevel::VAULT_1024) {
            return double_sha512_hex(ss.str());
        }
        return sha512_hex(ss.str());
    }

    // Validate with fee check
    bool validate() const {
        if (source.empty() || destination.empty()) return false;
        if (amount == 0) return false;  // Must send at least 1 Bite
        if (fee == 0) return false;     // Must include fee
        if (timestamp <= 0) return false;
        if (amount + fee > TOTAL_BITES_SUPPLY) return false; // Can't exceed supply
        return true;
    }
};
