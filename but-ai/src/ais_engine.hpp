// BUT Network AIS - AI Shield Engine
// Real-time behavior analysis & anomaly detection

#pragma once

#include <vector>
#include <string>
#include <map>
#include <deque>
#include <cmath>
#include <algorithm>
#include <numeric>
#include <random>
#include <sstream>
#include <iomanip>
#include <openssl/sha.h>

namespace but {
namespace ais {

// ==================== Transaction Profile ====================

struct TxProfile {
    std::string sender;
    std::string receiver;
    uint64_t amount;
    int64_t timestamp;
    std::string tx_type;
    double risk_score;
};

// ==================== Behavior Pattern ====================

struct BehaviorPattern {
    double avg_amount;
    double std_amount;
    double avg_frequency;  // TX per hour
    int total_tx;
    int64_t first_seen;
    int64_t last_seen;
    std::vector<std::string> known_peers;
};

class AISEngine {
private:
    // User behavior database
    std::map<std::string, BehaviorPattern> patterns;
    std::deque<TxProfile> recent_txs;
    static constexpr size_t MAX_RECENT = 1000;
    
    // Risk thresholds
    static constexpr double HIGH_RISK = 0.7;
    static constexpr double MEDIUM_RISK = 0.4;
    static constexpr double LOW_RISK = 0.15;
    
    // Anomaly detection parameters
    static constexpr double ZSCORE_THRESHOLD = 3.0;
    static constexpr uint64_t LARGE_TX_THRESHOLD = 1000000; // 1000 BUT
    
    // Calculate Z-score for anomaly detection
    double calculate_zscore(double value, double mean, double std_dev) {
        if (std_dev < 0.001) return 0.0;
        return (value - mean) / std_dev;
    }

    // Calculate moving average
    double calculate_moving_average(const std::vector<double>& values, size_t window) {
        if (values.empty()) return 0.0;
        size_t n = std::min(window, values.size());
        double sum = 0.0;
        for (size_t i = values.size() - n; i < values.size(); ++i) {
            sum += values[i];
        }
        return sum / n;
    }

    // Calculate standard deviation
    double calculate_std_dev(const std::vector<double>& values, double mean) {
        if (values.size() < 2) return 0.0;
        double sum_sq = 0.0;
        for (double v : values) {
            sum_sq += (v - mean) * (v - mean);
        }
        return std::sqrt(sum_sq / (values.size() - 1));
    }

    // Check if address is new (first seen)
    bool is_new_address(const std::string& address) {
        return patterns.find(address) == patterns.end();
    }

    // Check for rapid transactions (possible spam/bot)
    bool is_rapid_fire(const std::string& sender, int64_t current_time) {
        int count = 0;
        int64_t window_start = current_time - 60; // Last 60 seconds
        
        for (const auto& tx : recent_txs) {
            if (tx.sender == sender && tx.timestamp > window_start) {
                count++;
            }
        }
        
        return count > 10; // More than 10 TX per minute
    }

    // Check for unusual amount
    bool is_unusual_amount(const std::string& sender, uint64_t amount) {
        auto it = patterns.find(sender);
        if (it == patterns.end()) return false;
        
        const auto& pattern = it->second;
        double zscore = calculate_zscore(
            static_cast<double>(amount),
            pattern.avg_amount,
            pattern.std_amount
        );
        
        return std::abs(zscore) > ZSCORE_THRESHOLD;
    }

    // Check for known malicious patterns
    bool matches_malicious_pattern(const TxProfile& tx) {
        // Check for common scam patterns
        if (tx.amount == 0 && tx.tx_type == "contract") {
            return true; // Zero-value contract call (possible phishing)
        }
        
        // Check for dust attacks
        if (tx.amount < 100 && tx.amount > 0) { // Less than 0.1 BUT
            // Dust attack detection
            auto it = patterns.find(tx.sender);
            if (it != patterns.end() && it->second.total_tx < 5) {
                return true;
            }
        }
        
        return false;
    }

public:
    // ==================== Risk Scoring ====================
    
    double calculate_risk_score(const TxProfile& tx) {
        double risk = 0.0;
        int factors = 0;
        
        // Factor 1: New address
        if (is_new_address(tx.sender)) {
            risk += 0.3;
            factors++;
        }
        
        // Factor 2: Rapid fire transactions
        if (is_rapid_fire(tx.sender, tx.timestamp)) {
            risk += 0.4;
            factors++;
        }
        
        // Factor 3: Unusual amount
        if (is_unusual_amount(tx.sender, tx.amount)) {
            risk += 0.25;
            factors++;
        }
        
        // Factor 4: Large transaction from new user
        if (tx.amount > LARGE_TX_THRESHOLD && is_new_address(tx.sender)) {
            risk += 0.5;
            factors++;
        }
        
        // Factor 5: Malicious pattern match
        if (matches_malicious_pattern(tx)) {
            risk += 0.6;
            factors++;
        }
        
        // Factor 6: Unknown receiver
        auto sender_it = patterns.find(tx.sender);
        if (sender_it != patterns.end()) {
            const auto& known = sender_it->second.known_peers;
            if (std::find(known.begin(), known.end(), tx.receiver) == known.end()) {
                risk += 0.15;
                factors++;
            }
        }
        
        return (factors > 0) ? std::min(risk / std::sqrt(factors), 1.0) : 0.05;
    }

    // ==================== Decision Engine ====================
    
    enum class Action {
        ALLOW,
        FLAG,
        DELAY,
        BLOCK
    };

    struct Decision {
        Action action;
        double risk_score;
        std::string reason;
    };

    Decision evaluate_transaction(const TxProfile& tx) {
        double risk = calculate_risk_score(tx);
        Decision decision;
        decision.risk_score = risk;
        
        if (risk >= HIGH_RISK) {
            decision.action = Action::BLOCK;
            decision.reason = "High risk score: " + std::to_string(risk);
        } else if (risk >= MEDIUM_RISK) {
            decision.action = Action::DELAY;
            decision.reason = "Medium risk - additional verification required";
        } else if (risk >= LOW_RISK) {
            decision.action = Action::FLAG;
            decision.reason = "Low risk - flagged for review";
        } else {
            decision.action = Action::ALLOW;
            decision.reason = "Normal transaction";
        }
        
        return decision;
    }

    // ==================== Learning Engine ====================
    
    void learn_from_transaction(const TxProfile& tx) {
        // Update behavior pattern
        auto& pattern = patterns[tx.sender];
        pattern.total_tx++;
        pattern.last_seen = tx.timestamp;
        
        if (pattern.first_seen == 0) {
            pattern.first_seen = tx.timestamp;
        }
        
        // Update running statistics using Welford's method
        double old_mean = pattern.avg_amount;
        pattern.avg_amount += (static_cast<double>(tx.amount) - old_mean) / pattern.total_tx;
        
        if (pattern.total_tx > 1) {
            pattern.std_amount = std::sqrt(
                ((pattern.total_tx - 2) * pattern.std_amount * pattern.std_amount +
                 (static_cast<double>(tx.amount) - old_mean) * 
                 (static_cast<double>(tx.amount) - pattern.avg_amount)) /
                (pattern.total_tx - 1)
            );
        }
        
        // Update frequency
        if (pattern.first_seen != pattern.last_seen) {
            double hours = (pattern.last_seen - pattern.first_seen) / 3600.0;
            pattern.avg_frequency = (hours > 0) ? pattern.total_tx / hours : 0;
        }
        
        // Update known peers
        if (std::find(pattern.known_peers.begin(), 
                      pattern.known_peers.end(), 
                      tx.receiver) == pattern.known_peers.end()) {
            pattern.known_peers.push_back(tx.receiver);
            if (pattern.known_peers.size() > 50) {
                pattern.known_peers.erase(pattern.known_peers.begin());
            }
        }
        
        // Store in recent transactions
        recent_txs.push_back(tx);
        if (recent_txs.size() > MAX_RECENT) {
            recent_txs.pop_front();
        }
    }

    // ==================== Reporting ====================
    
    struct SecurityReport {
        int total_analyzed;
        int blocked;
        int delayed;
        int flagged;
        int allowed;
        double avg_risk_score;
    };

    SecurityReport generate_report() const {
        SecurityReport report = {0, 0, 0, 0, 0, 0.0};
        
        double total_risk = 0.0;
        for (const auto& tx : recent_txs) {
            report.total_analyzed++;
            total_risk += tx.risk_score;
            
            if (tx.risk_score >= HIGH_RISK) report.blocked++;
            else if (tx.risk_score >= MEDIUM_RISK) report.delayed++;
            else if (tx.risk_score >= LOW_RISK) report.flagged++;
            else report.allowed++;
        }
        
        if (report.total_analyzed > 0) {
            report.avg_risk_score = total_risk / report.total_analyzed;
        }
        
        return report;
    }

    // Get pattern info for debugging
    std::string get_pattern_info(const std::string& address) const {
        auto it = patterns.find(address);
        if (it == patterns.end()) return "No pattern data";
        
        std::stringstream ss;
        ss << "TXs: " << it->second.total_tx
           << " | Avg: " << std::fixed << std::setprecision(2) << it->second.avg_amount
           << " | Freq: " << it->second.avg_frequency << "/hr"
           << " | Peers: " << it->second.known_peers.size();
        return ss.str();
    }
};

} // namespace ais
} // namespace but
