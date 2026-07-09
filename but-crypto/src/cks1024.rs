// CKS-1024: Ultra Security Mode (Vault)
// 1024-bit keys for mission-critical operations
// Double HKDF-SHA512 expansion with domain separation

use rand::RngCore;
use sha2::Sha512;
use hkdf::Hkdf;
use zeroize::Zeroize;
use serde::{Serialize, Deserialize};

/// 1024-bit = 128 bytes
pub const SEED_1024: usize = 128;
pub const KEY_1024: usize = 128;

/// Ultra-secure vault keypair
#[derive(Clone, Serialize, Deserialize)]
pub struct VaultKeyPair {
    pub primary_key: [u8; KEY_1024],
    pub secondary_key: [u8; KEY_1024],
    pub vault_nonce: [u8; 32],
}

impl VaultKeyPair {
    /// Generate new 1024-bit vault keys
    pub fn generate() -> Self {
        let mut seed = [0u8; SEED_1024];
        rand::thread_rng().fill_bytes(&mut seed);
        let pair = Self::from_seed(&seed);
        seed.zeroize();
        pair
    }

    /// Derive 1024-bit keys from seed
    pub fn from_seed(seed: &[u8; SEED_1024]) -> Self {
        let hk = Hkdf::<Sha512>::new(Some(b"CKS-1024-VAULT"), seed);

        let mut primary_key = [0u8; KEY_1024];
        // Double expansion for 1024-bit output
        let mut half1 = [0u8; 64];
        let mut half2 = [0u8; 64];
        hk.expand(b"BUT-Vault-Primary-1", &mut half1).unwrap();
        hk.expand(b"BUT-Vault-Primary-2", &mut half2).unwrap();
        primary_key[..64].copy_from_slice(&half1);
        primary_key[64..].copy_from_slice(&half2);

        let mut secondary_key = [0u8; KEY_1024];
        hk.expand(b"BUT-Vault-Secondary-1", &mut half1).unwrap();
        hk.expand(b"BUT-Vault-Secondary-2", &mut half2).unwrap();
        secondary_key[..64].copy_from_slice(&half1);
        secondary_key[64..].copy_from_slice(&half2);

        let mut vault_nonce = [0u8; 32];
        hk.expand(b"BUT-Vault-Nonce", &mut vault_nonce).unwrap();

        VaultKeyPair { primary_key, secondary_key, vault_nonce }
    }

    /// Verify vault integrity
    pub fn verify_integrity(&self) -> bool {
        // Both keys must be non-zero and different from each other
        self.primary_key != [0u8; KEY_1024] 
            && self.secondary_key != [0u8; KEY_1024]
            && self.primary_key != self.secondary_key
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_1024_generation() {
        let pair = VaultKeyPair::generate();
        assert!(pair.verify_integrity());
    }

    #[test]
    fn test_1024_size() {
        let pair = VaultKeyPair::generate();
        assert_eq!(pair.primary_key.len(), 128);
        assert_eq!(pair.secondary_key.len(), 128);
    }
}
