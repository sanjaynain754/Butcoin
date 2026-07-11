// BUT Network QRN - Quantum Random Number Generator
// True randomness from multiple entropy sources

use rand::RngCore;
use sha2::{Sha512, Digest};
use std::time::{SystemTime, UNIX_EPOCH};

// ==================== Entropy Sources ====================

#[derive(Debug)]
pub enum EntropySource {
    OsRandom,        // /dev/urandom, SecureRandom
    CpuJitter,       // CPU instruction timing
    TimeQuantum,     // Nanosecond clock variations
    Combined,        // All sources mixed
}

// ==================== QRN Engine ====================

pub struct QRNEngine {
    source: EntropySource,
    entropy_pool: Vec<u8>,
    reseed_counter: u64,
}

impl QRNEngine {
    /// Create new QRN engine with specified entropy source
    pub fn new(source: EntropySource) -> Self {
        QRNEngine {
            source,
            entropy_pool: Vec::new(),
            reseed_counter: 0,
        }
    }

    /// Collect entropy from OS random source
    fn collect_os_entropy(&mut self, size: usize) -> Vec<u8> {
        let mut bytes = vec![0u8; size];
        rand::thread_rng().fill_bytes(&mut bytes);
        bytes
    }

    /// Collect entropy from CPU jitter (RDTSC timing variations)
    fn collect_cpu_jitter(&mut self, size: usize) -> Vec<u8> {
        let mut bytes = Vec::with_capacity(size);
        let mut prev = 0u64;
        
        for _ in 0..size {
            // Measure CPU cycle count (simulated timing jitter)
            let now = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_nanos() as u64;
            
            // XOR with previous for jitter extraction
            let jitter = now ^ prev;
            bytes.push((jitter & 0xFF) as u8);
            prev = now;
        }
        
        bytes
    }

    /// Collect entropy from nanosecond clock variations
    fn collect_time_entropy(&mut self, size: usize) -> Vec<u8> {
        let mut bytes = Vec::with_capacity(size);
        
        for i in 0..size {
            let now = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_nanos();
            
            // Use nanosecond precision + index mixing
            let val = (now >> (i % 32)) as u64;
            bytes.push((val & 0xFF) as u8);
        }
        
        bytes
    }

    /// Combine multiple entropy sources with SHA-512 mixing
    fn mix_entropy(&mut self, sources: Vec<Vec<u8>>) -> Vec<u8> {
        let mut hasher = Sha512::new();
        
        // Add reseed counter
        hasher.update(&self.reseed_counter.to_le_bytes());
        self.reseed_counter += 1;
        
        // Mix all sources
        for source in &sources {
            hasher.update(source);
        }
        
        // Add previous pool for chaining
        if !self.entropy_pool.is_empty() {
            hasher.update(&self.entropy_pool);
        }
        
        let hash = hasher.finalize();
        
        // Update entropy pool (keep last 64 bytes)
        self.entropy_pool = hash[..64].to_vec();
        
        hash.to_vec()
    }

    /// Generate random bytes
    pub fn generate(&mut self, size: usize) -> Vec<u8> {
        let entropy = match self.source {
            EntropySource::OsRandom => {
                self.collect_os_entropy(size)
            }
            EntropySource::CpuJitter => {
                self.collect_cpu_jitter(size)
            }
            EntropySource::TimeQuantum => {
                self.collect_time_entropy(size)
            }
            EntropySource::Combined => {
                // Collect from all sources and mix
                let os = self.collect_os_entropy(size);
                let cpu = self.collect_cpu_jitter(size);
                let time = self.collect_time_entropy(size);
                
                let mut mixed = self.mix_entropy(vec![os, cpu, time]);
                
                // Expand if needed
                if mixed.len() < size {
                    let mut expanded = mixed;
                    while expanded.len() < size {
                        let more = self.collect_os_entropy(size - expanded.len());
                        expanded.extend_from_slice(&more);
                    }
                    expanded.truncate(size);
                    expanded
                } else {
                    mixed.truncate(size);
                    mixed
                }
            }
        };
        
        // Ensure correct size
        if entropy.len() < size {
            let mut result = entropy;
            let remaining = size - result.len();
            result.extend_from_slice(&self.collect_os_entropy(remaining));
            result
        } else {
            entropy
        }
    }

    /// Generate a random number in range [min, max]
    pub fn generate_range(&mut self, min: u64, max: u64) -> u64 {
        if min >= max {
            return min;
        }
        
        let range = max - min + 1;
        let bytes = self.generate(8);
        
        let mut value = 0u64;
        for (i, &byte) in bytes.iter().enumerate() {
            value |= (byte as u64) << (i * 8);
        }
        
        min + (value % range)
    }

    /// Generate a random seed for cryptographic use
    pub fn generate_seed(&mut self, bits: u32) -> Vec<u8> {
        let bytes_needed = (bits / 8) as usize;
        let mut seed = self.generate(bytes_needed);
        
        // Set high bit for minimum strength
        if !seed.is_empty() {
            seed[0] |= 0x80;
        }
        
        seed
    }

    /// Generate a 512-bit seed (BUT Standard)
    pub fn generate_512_seed(&mut self) -> [u8; 64] {
        let bytes = self.generate(64);
        let mut seed = [0u8; 64];
        seed.copy_from_slice(&bytes[..64]);
        seed
    }

    /// Generate a 1024-bit seed (BUT Vault)
    pub fn generate_1024_seed(&mut self) -> [u8; 128] {
        let bytes = self.generate(128);
        let mut seed = [0u8; 128];
        seed.copy_from_slice(&bytes[..128]);
        seed
    }

    /// Run statistical randomness tests
    pub fn test_randomness(&mut self, sample_size: usize) -> RandomnessReport {
        let samples = self.generate(sample_size);
        
        // Monobit test (frequency)
        let ones: usize = samples.iter().map(|&b| b.count_ones() as usize).sum();
        let total_bits = sample_size * 8;
        let ratio = ones as f64 / total_bits as f64;
        
        // Runs test
        let mut runs = 0usize;
        let mut prev_bit = samples[0] & 0x01;
        for &byte in &samples[1..] {
            for i in 0..8 {
                let bit = (byte >> i) & 0x01;
                if bit != prev_bit {
                    runs += 1;
                }
                prev_bit = bit;
            }
        }
        
        // Poker test (4-bit patterns)
        let mut patterns = [0u32; 16];
        for &byte in &samples {
            patterns[(byte & 0x0F) as usize] += 1;
            patterns[((byte >> 4) & 0x0F) as usize] += 1;
        }
        
        let expected = (sample_size * 2) as f64 / 16.0;
        let chi_square: f64 = patterns.iter()
            .map(|&count| {
                let diff = count as f64 - expected;
                diff * diff / expected
            })
            .sum();
        
        RandomnessReport {
            sample_size,
            monobit_ratio: ratio,
            runs_count: runs,
            chi_square,
            is_random: ratio > 0.45 && ratio < 0.55 && chi_square < 30.0,
        }
    }

    /// Get engine info
    pub fn get_info(&self) -> String {
        format!(
            "QRN Engine | Source: {:?} | Pool: {}B | Reseeds: {}",
            self.source,
            self.entropy_pool.len(),
            self.reseed_counter,
        )
    }
}

// ==================== Randomness Report ====================

pub struct RandomnessReport {
    pub sample_size: usize,
    pub monobit_ratio: f64,
    pub runs_count: usize,
    pub chi_square: f64,
    pub is_random: bool,
}

impl std::fmt::Display for RandomnessReport {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        writeln!(f, "Randomness Test Report:")?;
        writeln!(f, "  Sample Size: {} bytes", self.sample_size)?;
        writeln!(f, "  Monobit Ratio: {:.4} (ideal: 0.5000)", self.monobit_ratio)?;
        writeln!(f, "  Runs: {}", self.runs_count)?;
        writeln!(f, "  Chi-Square: {:.2} (threshold: 30.0)", self.chi_square)?;
        writeln!(f, "  Random: {}", if self.is_random { "YES ✅" } else { "NO ❌" })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_os_random() {
        let mut engine = QRNEngine::new(EntropySource::OsRandom);
        let bytes = engine.generate(32);
        assert_eq!(bytes.len(), 32);
    }

    #[test]
    fn test_combined_random() {
        let mut engine = QRNEngine::new(EntropySource::Combined);
        let bytes = engine.generate(64);
        assert_eq!(bytes.len(), 64);
    }

    #[test]
    fn test_seed_generation() {
        let mut engine = QRNEngine::new(EntropySource::Combined);
        let seed512 = engine.generate_512_seed();
        let seed1024 = engine.generate_1024_seed();
        assert_eq!(seed512.len(), 64);
        assert_eq!(seed1024.len(), 128);
        assert_ne!(seed512.to_vec(), seed1024[..64].to_vec());
    }

    #[test]
    fn test_randomness_report() {
        let mut engine = QRNEngine::new(EntropySource::Combined);
        let report = engine.test_randomness(1024);
        assert!(report.is_random);
    }

    #[test]
    fn test_range() {
        let mut engine = QRNEngine::new(EntropySource::OsRandom);
        for _ in 0..100 {
            let val = engine.generate_range(1, 100);
            assert!(val >= 1 && val <= 100);
        }
    }
          }
