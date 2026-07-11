// CKS-512: Standard Security Layer
// Classical HKDF-SHA512 based key derivation
// Prepares interface for hybrid post-quantum integration

use rand::RngCore;
use sha2::Sha512;
use hkdf::Hkdf;
use zeroize::Zeroize;
use serde::{Serialize, Deserialize};

/// 512-bit = 64 bytes
pub const SEED_512: usize = 64;
pub const KEY_512: usize = 64;

/// Standard keypair with 512-bit keys
#[derive(Clone)]
pub struct StandardKeyPair {
    pub spend_key: [u8; KEY_512],
    pub view_key: [u8; KEY_512],
    pub chain_code: [u8; 32], // For HD derivation
}

impl StandardKeyPair {
    /// Generate new random 512-bit seed and derive keys
    pub fn generate() -> Self {
        let mut seed = [0u8; SEED_512];
        rand::thread_rng().fill_bytes(&mut seed);
        let pair = Self::from_seed(&seed);
        seed.zeroize();
        pair
    }

    /// Derive keys from existing 512-bit seed
    pub fn from_seed(seed: &[u8; SEED_512]) -> Self {
        // HKDF-SHA512 for stronger derivation
        let hk = Hkdf::<Sha512>::new(Some(b"CKS-512-SALT"), seed);

        let mut spend_key = [0u8; KEY_512];
        hk.expand(b"BUT-Spend-512", &mut spend_key)
            .expect("HKDF expand failed");

        let mut view_key = [0u8; KEY_512];
        hk.expand(b"BUT-View-512", &mut view_key)
            .expect("HKDF expand failed");

        let mut chain_code = [0u8; 32];
        hk.expand(b"BUT-Chain-512", &mut chain_code)
            .expect("HKDF expand failed");

        StandardKeyPair { spend_key, view_key, chain_code }
    }

    /// Get public-facing view key only (for audits)
    pub fn get_view_only(&self) -> [u8; KEY_512] {
        self.view_key
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_512_key_generation() {
        let pair = StandardKeyPair::generate();
        assert_ne!(pair.spend_key, [0u8; 64]);
        assert_ne!(pair.view_key, [0u8; 64]);
        assert_ne!(pair.spend_key, pair.view_key);
    }

    #[test]
    fn test_deterministic() {
        let seed = [7u8; 64];
        let a = StandardKeyPair::from_seed(&seed);
        let b = StandardKeyPair::from_seed(&seed);
        assert_eq!(a.spend_key, b.spend_key);
    }
  }
