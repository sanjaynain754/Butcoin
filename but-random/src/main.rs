// BUT Network QRN - Quantum Random Number Generator
// True randomness from multiple entropy sources

mod qrn_engine;

use qrn_engine::{QRNEngine, EntropySource};

fn main() {
    println!("=== BUT QRN - Quantum Random Numbers ===\n");

    // ==================== Test 1: OS Random ====================
    println!("--- Test 1: OS Random (SecureRandom) ---");
    let mut engine = QRNEngine::new(EntropySource::OsRandom);
    
    let rand_bytes = engine.generate(32);
    println!("Generated: {}...", hex::encode(&rand_bytes[..16]));
    println!("Size: {} bytes", rand_bytes.len());

    // ==================== Test 2: CPU Jitter ====================
    println!("\n--- Test 2: CPU Jitter Entropy ---");
    let mut jitter_engine = QRNEngine::new(EntropySource::CpuJitter);
    
    let jitter_bytes = jitter_engine.generate(32);
    println!("Generated: {}...", hex::encode(&jitter_bytes[..16]));
    println!("Source: CPU instruction timing variations");

    // ==================== Test 3: Time Quantum ====================
    println!("\n--- Test 3: Time Quantum Entropy ---");
    let mut time_engine = QRNEngine::new(EntropySource::TimeQuantum);
    
    let time_bytes = time_engine.generate(32);
    println!("Generated: {}...", hex::encode(&time_bytes[..16]));
    println!("Source: Nanosecond clock variations");

    // ==================== Test 4: Combined (All Sources) ====================
    println!("\n--- Test 4: Combined Entropy (All Sources) ---");
    let mut combined_engine = QRNEngine::new(EntropySource::Combined);
    
    let combined_bytes = combined_engine.generate(64);
    println!("Generated: {}...", hex::encode(&combined_bytes[..16]));
    println!("Size: {} bytes", combined_bytes.len());
    println!("{}", combined_engine.get_info());

    // ==================== Test 5: Cryptographic Seeds ====================
    println!("\n--- Test 5: Cryptographic Seeds ---");
    
    let seed512 = combined_engine.generate_512_seed();
    let seed1024 = combined_engine.generate_1024_seed();
    
    println!("512-bit Seed: {}...", hex::encode(&seed512[..16]));
    println!("1024-bit Seed: {}...", hex::encode(&seed1024[..16]));
    println!("Unique: {}", seed512 != seed1024[..64]);

    // ==================== Test 6: Random Range ====================
    println!("\n--- Test 6: Random Range (1-1000) ---");
    
    let mut values = Vec::new();
    for _ in 0..5 {
        let val = combined_engine.generate_range(1, 1000);
        values.push(val);
    }
    println!("Random values: {:?}", values);
    println!("All unique: {}", {
        let mut unique = values.clone();
        unique.sort();
        unique.dedup();
        unique.len() == values.len()
    });

    // ==================== Test 7: Randomness Test ====================
    println!("\n--- Test 7: Statistical Randomness Test ---");
    
    let report = combined_engine.test_randomness(2048);
    println!("{}", report);

    // ==================== Performance ====================
    println!("\n--- Performance ---");
    let start = std::time::Instant::now();
    
    for _ in 0..1000 {
        combined_engine.generate(64);
    }
    
    let elapsed = start.elapsed();
    println!("1000 x 64B generations: {:?}", elapsed);
    println!("Per generation: {:?}", elapsed / 1000);

    println!("\n=== QRN Test Complete ===");
  }
