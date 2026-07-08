// BUT Network CKS - Cosmic Key Space
// Quantum-resistant key generation & BUT-S/BUT-V derivation

use rand::RngCore;
use sha2::Sha256;
use hkdf::Hkdf;
use zeroize::Zeroize;
use serde::{Serialize, Deserialize};

pub const SEED_SIZE: usize = 64;
pub const SPEND_KEY_SIZE: usize = 32;
pub const VIEW_KEY_SIZE: usize = 32;

#[derive(Clone, Serialize, Deserialize)]
pub struct CksKeyPair {
    pub spend_key: [u8; SPEND_KEY_SIZE],
    pub view_key: [u8; VIEW_KEY_SIZE],
}

impl CksKeyPair {
    pub fn generate() -> Self {
        let mut seed = [0u8; SEED_SIZE];
        rand::thread_rng().fill_bytes(&mut seed);
        let pair = Self::from_master_seed(&seed);
        seed.zeroize();
        pair
    }

    pub fn from_master_seed(seed: &[u8; SEED_SIZE]) -> Self {
        let hk = Hkdf::<Sha256>::new(None, seed);

        let mut spend_key = [0u8; SPEND_KEY_SIZE];
        hk.expand(b"BUT-Spend-Key", &mut spend_key)
            .expect("HKDF expand failed for spend key");

        let mut view_key = [0u8; VIEW_KEY_SIZE];
        hk.expand(b"BUT-View-Key", &mut view_key)
            .expect("HKDF expand failed for view key");

        CksKeyPair { spend_key, view_key }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_key_generation() {
        let pair = CksKeyPair::generate();
        assert_ne!(pair.spend_key, [0u8; 32]);
        assert_ne!(pair.view_key, [0u8; 32]);
        assert_ne!(pair.spend_key, pair.view_key);
    }

    #[test]
    fn test_deterministic_derivation() {
        let seed = [42u8; SEED_SIZE];
        let pair1 = CksKeyPair::from_master_seed(&seed);
        let pair2 = CksKeyPair::from_master_seed(&seed);
        assert_eq!(pair1.spend_key, pair2.spend_key);
        assert_eq!(pair1.view_key, pair2.view_key);
    }
      }
