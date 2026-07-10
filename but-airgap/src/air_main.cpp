// BUT Network AIR - Air-gapped Signing
// Offline transaction signing via QR/SD card

#include <iostream>
#include <vector>
#include <string>
#include <iomanip>
#include "air_engine.hpp"

using namespace but::air;

void print_hex(const std::string& label, const std::vector<uint8_t>& data) {
    std::cout << label << ": ";
    for (size_t i = 0; i < std::min(data.size(), size_t(16)); ++i) {
        std::cout << std::hex << std::setw(2) << std::setfill('0') << (int)data[i];
    }
    if (data.size() > 16) std::cout << "...";
    std::cout << std::dec << std::endl;
}

int main() {
    std::cout << "=== BUT AIR - Air-gapped Signing ===\n" << std::endl;
    std::cout << AIREngine::get_info() << "\n" << std::endl;

    AIREngine air;

    // ==================== Test 1: Initialize Offline Device ====================
    std::cout << "--- Test 1: Initialize Offline Device ---" << std::endl;
    
    bool init_ok = air.initialize_offline_device();
    std::cout << "Offline key generated: " << (init_ok ? "SUCCESS ✅" : "FAILED ❌") << std::endl;
    std::cout << "(Key never connected to internet)\n" << std::endl;

    // ==================== Test 2: Prepare Transaction (Online) ====================
    std::cout << "--- Test 2: Prepare Transaction (Online Hot Wallet) ---" << std::endl;
    
    auto tx = air.prepare_transaction(
        "but://alice",
        "but://bob",
        500000,  // 500 BUT in Bites
        100      // Fee in Bites
    );
    
    std::cout << "TX ID: " << tx.tx_id << std::endl;
    std::cout << "From: " << tx.from_address << std::endl;
    std::cout << "To: " << tx.to_address << std::endl;
    std::cout << "Amount: " << tx.amount << " Bites" << std::endl;
    std::cout << "Signed: " << (tx.signed_ ? "YES" : "NO (pending offline signing)") << std::endl;
    print_hex("Unsigned Hash", tx.unsigned_hash);

    // ==================== Test 3: QR Code Transfer ====================
    std::cout << "\n--- Test 3: QR Code Transfer to Offline Device ---" << std::endl;
    
    auto qr = air.create_qr_code(tx);
    std::cout << "QR Version: " << qr.version << std::endl;
    std::cout << "QR Data: " << qr.encoded_data.substr(0, 40) << "..." << std::endl;
    print_hex("QR Checksum", qr.checksum);
    std::cout << "(QR displayed on online device, scanned by offline device)\n" << std::endl;

    // ==================== Test 4: Sign Offline ====================
    std::cout << "--- Test 4: Sign Transaction (Offline Cold Wallet) ---" << std::endl;
    
    auto signed_tx = air.sign_from_qr(qr);
    signed_tx.tx_id = tx.tx_id;
    signed_tx.from_address = tx.from_address;
    signed_tx.to_address = tx.to_address;
    signed_tx.amount = tx.amount;
    signed_tx.fee = tx.fee;
    
    std::cout << "Signed offline: " << (signed_tx.signed_ ? "YES ✅" : "NO ❌") << std::endl;
    print_hex("Signature", signed_tx.signature);
    std::cout << "(Key never left offline device!)\n" << std::endl;

    // ==================== Test 5: Verify Signed Transaction (Online) ====================
    std::cout << "--- Test 5: Verify Signed Transaction (Online) ---" << std::endl;
    
    bool verified = air.verify_signed_transaction(signed_tx);
    std::cout << "Verification: " << (verified ? "VALID ✅" : "INVALID ❌") << std::endl;
    
    if (verified) {
        std::cout << "Transaction ready to broadcast!" << std::endl;
    }

    // ==================== Test 6: SD Card Transfer ====================
    std::cout << "\n--- Test 6: SD Card Transfer ---" << std::endl;
    
    auto sd_export = air.export_to_sd(tx, "/secure/offline");
    std::cout << "File: " << sd_export.file_name << std::endl;
    std::cout << "Size: " << sd_export.file_data.size() << " bytes" << std::endl;
    print_hex("File Hash", sd_export.file_hash);
    std::cout << "(File saved to SD card for offline signing)\n" << std::endl;

    auto sd_import = air.import_from_sd(sd_export);
    std::cout << "SD Import: " << (sd_import.signed_ ? "SUCCESS ✅" : "FAILED ❌") << std::endl;

    // ==================== Test 7: Tamper Detection ====================
    std::cout << "\n--- Test 7: Tamper Detection ---" << std::endl;
    
    auto tampered_qr = qr;
    tampered_qr.encoded_data[5] ^= 0xFF; // Modify QR data
    auto tampered_tx = air.sign_from_qr(tampered_qr);
    
    bool tampered_ok = air.verify_signed_transaction(tampered_tx);
    std::cout << "Tampered TX: " << (tampered_ok ? "ACCEPTED ❌" : "REJECTED ✅") << std::endl;

    std::cout << "\n=== AIR Test Complete ===" << std::endl;
    return 0;
}
