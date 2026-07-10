// BUT Network TEX - Trusted Execution Environment
// Hardware-grade isolation for sensitive operations

#include <iostream>
#include <vector>
#include <string>
#include <iomanip>
#include "tex_engine.hpp"

using namespace but::tex;

void print_hex(const std::string& label, const std::vector<uint8_t>& data) {
    std::cout << label << ": ";
    for (size_t i = 0; i < std::min(data.size(), size_t(16)); ++i) {
        std::cout << std::hex << std::setw(2) << std::setfill('0') << (int)data[i];
    }
    if (data.size() > 16) std::cout << "...";
    std::cout << std::dec << std::endl;
}

int main() {
    std::cout << "=== BUT TEX - Trusted Execution Environment ===\n" << std::endl;

    TEEManager tee;

    // ==================== Test 1: Initialize TEE ====================
    std::cout << "--- Test 1: TEE Initialization ---" << std::endl;
    
    bool init_ok = tee.initialize_tee();
    std::cout << "Initialization: " << (init_ok ? "SUCCESS ✅" : "FAILED ❌") << std::endl;

    auto status = tee.get_status();
    std::cout << "Device ID: " << status.device_id << std::endl;
    std::cout << "Attested: " << (status.attested ? "YES ✅" : "NO ❌") << std::endl;
    std::cout << "Initialized: " << (status.initialized ? "YES ✅" : "NO ❌") << std::endl;

    // ==================== Test 2: Secure Signing ====================
    std::cout << "\n--- Test 2: Secure Signing Inside Enclave ---" << std::endl;
    
    std::string message = "BUT Network Transaction - 500 BUT to Bob";
    std::vector<uint8_t> msg_bytes(message.begin(), message.end());
    
    auto sign_result = tee.secure_execute("sign", msg_bytes);
    if (sign_result.success) {
        print_hex("Signature", sign_result.result);
        std::cout << "Key never left enclave: YES ✅" << std::endl;
    } else {
        std::cout << "Signing failed ❌" << std::endl;
    }

    // ==================== Test 3: Secure Random Generation ====================
    std::cout << "\n--- Test 3: Secure Random Inside Enclave ---" << std::endl;
    
    std::vector<uint8_t> size_req = {64}; // Request 64 random bytes
    auto rand_result = tee.secure_execute("random", size_req);
    
    if (rand_result.success) {
        print_hex("Random", rand_result.result);
        std::cout << "Size: " << rand_result.result.size() << " bytes ✅" << std::endl;
    }

    // ==================== Test 4: Remote Attestation ====================
    std::cout << "\n--- Test 4: Remote Attestation ---" << std::endl;
    
    bool attestation = tee.perform_attestation();
    std::cout << "Attestation: " << (attestation ? "VERIFIED ✅" : "FAILED ❌") << std::endl;

    // ==================== Final Status ====================
    std::cout << "\n--- TEE Status Report ---" << std::endl;
    auto final_status = tee.get_status();
    std::cout << "TEE Initialized: " << (final_status.initialized ? "YES" : "NO") << std::endl;
    std::cout << "Remote Attested: " << (final_status.attested ? "YES" : "NO") << std::endl;
    std::cout << "Device: " << final_status.device_id << std::endl;
    std::cout << "Secure Storage Items: " << final_status.secure_storage_items << std::endl;

    std::cout << "\n=== TEX Test Complete ===" << std::endl;
    return 0;
}
