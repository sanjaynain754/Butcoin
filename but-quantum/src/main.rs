// BUT Network QSH - Quantum Sign Handler
// Post-Quantum signature generation & verification

mod qsh_engine;

use qsh_engine::QSHEngine;

fn main() {
    println!("=== BUT QSH - Quantum Sign Handler ===\n");

    // Test all security levels
    let levels = [2u32, 3, 5];
    let level_names = ["Dilithium2 (128-bit)", "Dilithium3 (192-bit)", "Dilithium5 (256-bit)"];

    for (i, &level) in levels.iter().enumerate() {
        println!("--- {} ---", level_names[i]);
        
        let engine = QSHEngine::new(level);
        println!("{}", engine.get_security_info());

        // Generate keypair
        let kp = engine.generate_keypair();
        println!("Public Key: {}...", hex::encode(&kp.public_key[..16]));
        println!("Algorithm: {}", kp.algorithm);

        // Sign a message
        let message = b"BUT Network - Blockchain Universe Technology";
        let sig = engine.sign(&kp, message);
        println!("Signature: {}...", hex::encode(&sig.signature[..16]));

        // Verify
        let valid = engine.verify(&kp.public_key, message, &sig);
        println!("Verification: {}\n", if valid { "✅ VALID" } else { "❌ INVALID" });

        // Tamper test
        let mut tampered = sig.clone();
        tampered.signature[10] ^= 0xFF;
        let tampered_valid = engine.verify(&kp.public_key, message, &tampered);
        println!("Tampered Test: {}\n", if tampered_valid { "❌ SHOULD FAIL" } else { "✅ CORRECTLY REJECTED" });
    }

    // Benchmark
    println!("--- Performance Benchmark ---");
    let engine = QSHEngine::new(3);
    let kp = engine.generate_keypair();
    let msg = b"Benchmark message for BUT Network";

    let start = std::time::Instant::now();
    for _ in 0..100 {
        let sig = engine.sign(&kp, msg);
        engine.verify(&kp.public_key, msg, &sig);
    }
    let elapsed = start.elapsed();
    println!("100 sign+verify cycles: {:?}", elapsed);
    println!("Avg per cycle: {:?}", elapsed / 100);

    println!("\n=== QSH Test Complete ===");
  }
