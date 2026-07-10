// BUT Network DID - Decentralized Identity
// W3C-compliant Self-Sovereign Identity system

#pragma once

#include <vector>
#include <string>
#include <map>
#include <chrono>
#include <random>
#include <sstream>
#include <iomanip>
#include <openssl/sha.h>
#include <openssl/rand.h>

namespace but {
namespace did {

// ==================== DID Document ====================

struct DIDDocument {
    std::string did;                    // did:but:0x1234...
    std::string controller;             // Who controls this DID
    std::vector<std::string> public_keys;  // Associated public keys
    std::vector<std::string> services;     // Linked services
    int64_t created;
    int64_t updated;
    std::string version;
    bool revoked;
};

// ==================== Verifiable Credential ====================

struct VerifiableCredential {
    std::string id;
    std::string issuer;                 // DID of issuer
    std::string subject;                // DID of subject
    std::string credential_type;        // e.g., "KYC", "AgeProof", "Membership"
    std::map<std::string, std::string> claims;  // Key-value claims
    int64_t issued_at;
    int64_t expires_at;
    std::vector<uint8_t> issuer_signature;
    bool verified;
};

// ==================== DID Engine ====================

class DIDEngine {
private:
    std::map<std::string, DIDDocument> did_registry;
    std::vector<VerifiableCredential> credentials;

    // Generate unique DID
    std::string generate_did() {
        std::vector<uint8_t> random(32);
        RAND_bytes(random.data(), 32);

        uint8_t hash[SHA256_DIGEST_LENGTH];
        SHA256(random.data(), random.size(), hash);

        std::stringstream ss;
        ss << "did:but:";
        for (int i = 0; i < 20; ++i) {
            ss << std::hex << std::setw(2) << std::setfill('0') << (int)hash[i];
        }
        return ss.str();
    }

    // Sign data with issuer's key (simulated)
    std::vector<uint8_t> sign_data(const std::string& issuer, const std::vector<uint8_t>& data) {
        std::vector<uint8_t> combined(issuer.begin(), issuer.end());
        combined.insert(combined.end(), data.begin(), data.end());

        uint8_t sig[SHA256_DIGEST_LENGTH];
        SHA256(combined.data(), combined.size(), sig);
        return std::vector<uint8_t>(sig, sig + SHA256_DIGEST_LENGTH);
    }

    // Verify signature
    bool verify_signature(const std::string& issuer,
                          const std::vector<uint8_t>& data,
                          const std::vector<uint8_t>& signature) {
        auto expected = sign_data(issuer, data);
        return expected == signature;
    }

public:
    // Create a new DID
    DIDDocument create_did(const std::vector<std::string>& public_keys = {},
                           const std::vector<std::string>& services = {}) {
        DIDDocument doc;
        doc.did = generate_did();
        doc.controller = doc.did;  // Self-controlled
        doc.public_keys = public_keys;
        doc.services = services;

        auto now = std::chrono::system_clock::now();
        doc.created = std::chrono::system_clock::to_time_t(now);
        doc.updated = doc.created;
        doc.version = "1.0";
        doc.revoked = false;

        did_registry[doc.did] = doc;
        return doc;
    }

    // Resolve a DID to its document
    DIDDocument* resolve_did(const std::string& did) {
        auto it = did_registry.find(did);
        if (it != did_registry.end() && !it->second.revoked) {
            return &it->second;
        }
        return nullptr;
    }

    // Update DID document
    bool update_did(const std::string& did,
                    const std::vector<std::string>& public_keys,
                    const std::vector<std::string>& services) {
        auto* doc = resolve_did(did);
        if (!doc) return false;

        doc->public_keys = public_keys;
        doc->services = services;
        doc->updated = std::chrono::system_clock::to_time_t(
            std::chrono::system_clock::now());
        
        return true;
    }

    // Revoke a DID
    bool revoke_did(const std::string& did) {
        auto* doc = resolve_did(did);
        if (!doc) return false;

        doc->revoked = true;
        doc->updated = std::chrono::system_clock::to_time_t(
            std::chrono::system_clock::now());
        
        return true;
    }

    // Issue a verifiable credential
    VerifiableCredential issue_credential(
        const std::string& issuer_did,
        const std::string& subject_did,
        const std::string& credential_type,
        const std::map<std::string, std::string>& claims,
        int64_t valid_days = 365) {

        VerifiableCredential vc;
        vc.id = "vc-" + generate_did().substr(8, 16);
        vc.issuer = issuer_did;
        vc.subject = subject_did;
        vc.credential_type = credential_type;
        vc.claims = claims;

        auto now = std::chrono::system_clock::now();
        vc.issued_at = std::chrono::system_clock::to_time_t(now);
        vc.expires_at = vc.issued_at + (valid_days * 86400);
        vc.verified = false;

        // Sign credential
        std::vector<uint8_t> cred_data;
        std::string combined = vc.id + vc.issuer + vc.subject + vc.credential_type;
        cred_data.assign(combined.begin(), combined.end());
        vc.issuer_signature = sign_data(issuer_did, cred_data);

        credentials.push_back(vc);
        return vc;
    }

    // Verify a credential
    bool verify_credential(VerifiableCredential& vc) {
        // Check if issuer exists and is not revoked
        auto* issuer_doc = resolve_did(vc.issuer);
        if (!issuer_doc) return false;

        // Check if subject exists and is not revoked
        auto* subject_doc = resolve_did(vc.subject);
        if (!subject_doc) return false;

        // Check expiration
        auto now = std::chrono::system_clock::now();
        int64_t now_ts = std::chrono::system_clock::to_time_t(now);
        if (now_ts > vc.expires_at) return false;

        // Verify signature
        std::vector<uint8_t> cred_data;
        std::string combined = vc.id + vc.issuer + vc.subject + vc.credential_type;
        cred_data.assign(combined.begin(), combined.end());

        vc.verified = verify_signature(vc.issuer, cred_data, vc.issuer_signature);
        return vc.verified;
    }

    // Get all credentials for a subject
    std::vector<VerifiableCredential> get_credentials(const std::string& subject_did) {
        std::vector<VerifiableCredential> result;
        for (const auto& vc : credentials) {
            if (vc.subject == subject_did) {
                result.push_back(vc);
            }
        }
        return result;
    }

    // Generate DID info string
    static std::string get_did_info(const DIDDocument& doc) {
        std::stringstream ss;
        ss << "DID: " << doc.did.substr(0, 20) << "...\n"
           << "  Controller: " << (doc.controller == doc.did ? "Self" : doc.controller.substr(0, 20)) << "\n"
           << "  Keys: " << doc.public_keys.size() << "\n"
           << "  Services: " << doc.services.size() << "\n"
           << "  Created: " << doc.created << "\n"
           << "  Revoked: " << (doc.revoked ? "YES" : "NO");
        return ss.str();
    }

    // Generate credential info string
    static std::string get_credential_info(const VerifiableCredential& vc) {
        std::stringstream ss;
        ss << "VC: " << vc.id << "\n"
           << "  Type: " << vc.credential_type << "\n"
           << "  Issuer: " << vc.issuer.substr(0, 20) << "...\n"
           << "  Subject: " << vc.subject.substr(0, 20) << "...\n"
           << "  Claims: " << vc.claims.size() << "\n"
           << "  Expires: " << vc.expires_at << "\n"
           << "  Verified: " << (vc.verified ? "YES ✅" : "NO ❌");
        return ss.str();
    }
};

} // namespace did
} // namespace but
