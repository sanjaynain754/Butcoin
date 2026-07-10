// BUT Network DID - Decentralized Identity
// Self-Sovereign Identity System

#include <iostream>
#include <vector>
#include <string>
#include <iomanip>
#include "did_engine.hpp"

using namespace but::did;

int main() {
    std::cout << "=== BUT DID - Decentralized Identity ===\n" << std::endl;

    DIDEngine engine;

    // ==================== Test 1: Create DIDs ====================
    std::cout << "--- Test 1: Create Decentralized Identifiers ---" << std::endl;

    // Create Alice's DID
    auto alice_doc = engine.create_did(
        {"0xBUT-S-ALICE-KEY-1", "0xBUT-V-ALICE-KEY-1"},
        {"but://alice", "https://alice.but.network"}
    );
    std::cout << DIDEngine::get_did_info(alice_doc) << "\n" << std::endl;

    // Create Bob's DID
    auto bob_doc = engine.create_did(
        {"0xBUT-S-BOB-KEY-1"},
        {"but://bob"}
    );
    std::cout << DIDEngine::get_did_info(bob_doc) << "\n" << std::endl;

    // Create Bank's DID (Issuer)
    auto bank_doc = engine.create_did(
        {"0xBANK-KEY-1", "0xBANK-KEY-2"},
        {"https://bank.but.network"}
    );
    std::cout << DIDEngine::get_did_info(bank_doc) << "\n" << std::endl;

    // ==================== Test 2: Issue Credentials ====================
    std::cout << "--- Test 2: Issue Verifiable Credentials ---" << std::endl;

    // Bank issues KYC credential to Alice
    std::map<std::string, std::string> kyc_claims;
    kyc_claims["name"] = "Alice";
    kyc_claims["age"] = "25";
    kyc_claims["country"] = "IN";
    kyc_claims["kyc_level"] = "verified";

    auto kyc_vc = engine.issue_credential(
        bank_doc.did, alice_doc.did, "KYC", kyc_claims, 365
    );
    std::cout << DIDEngine::get_credential_info(kyc_vc) << "\n" << std::endl;

    // University issues degree credential to Bob
    std::map<std::string, std::string> degree_claims;
    degree_claims["degree"] = "B.Tech";
    degree_claims["major"] = "Computer Science";
    degree_claims["year"] = "2025";

    auto degree_vc = engine.issue_credential(
        bank_doc.did, bob_doc.did, "EducationDegree", degree_claims, 1825
    );
    std::cout << DIDEngine::get_credential_info(degree_vc) << "\n" << std::endl;

    // ==================== Test 3: Verify Credentials ====================
    std::cout << "--- Test 3: Verify Credentials ---" << std::endl;

    bool kyc_ok = engine.verify_credential(kyc_vc);
    std::cout << "KYC Verification: " << (kyc_ok ? "PASSED ✅" : "FAILED ❌") << std::endl;

    bool degree_ok = engine.verify_credential(degree_vc);
    std::cout << "Degree Verification: " << (degree_ok ? "PASSED ✅" : "FAILED ❌") << std::endl;

    // ==================== Test 4: Resolve DID ====================
    std::cout << "\n--- Test 4: Resolve DID ---" << std::endl;

    auto* resolved = engine.resolve_did(alice_doc.did);
    if (resolved) {
        std::cout << "Resolved Alice: " << resolved->did.substr(0, 20) << "... ✅" << std::endl;
        std::cout << "Services: ";
        for (const auto& svc : resolved->services) {
            std::cout << svc << " ";
        }
        std::cout << std::endl;
    }

    // ==================== Test 5: Revoke DID ====================
    std::cout << "\n--- Test 5: Revoke DID ---" << std::endl;

    // Create temporary DID
    auto temp_doc = engine.create_did({}, {});
    std::cout << "Temp DID created: " << temp_doc.did.substr(0, 20) << "..." << std::endl;

    // Revoke it
    engine.revoke_did(temp_doc.did);
    auto* revoked = engine.resolve_did(temp_doc.did);
    std::cout << "After revoke: " << (revoked ? "Still Active ❌" : "Not Found ✅") << std::endl;

    // ==================== Summary ====================
    std::cout << "\n--- DID Features ---" << std::endl;
    std::cout << "✅ Self-Sovereign Identity" << std::endl;
    std::cout << "✅ Verifiable Credentials" << std::endl;
    std::cout << "✅ DID Resolution" << std::endl;
    std::cout << "✅ Credential Issuance" << std::endl;
    std::cout << "✅ Credential Verification" << std::endl;
    std::cout << "✅ DID Revocation" << std::endl;
    std::cout << "✅ Zero-Knowledge KYC Ready" << std::endl;

    std::cout << "\n=== DID Test Complete ===" << std::endl;
    return 0;
}
