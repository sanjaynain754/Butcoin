// BUT Network CKS - Cosmic Key Space
// Multi-level quantum-resistant cryptography
// 
// Modules:
// - cks512: Standard 512-bit security
// - cks1024: Ultra 1024-bit vault security
// - hybrid: Classical + Post-Quantum hybrid layer

pub mod cks512;
pub mod cks1024;
pub mod hybrid;

// Re-exports for easy access
pub use cks512::StandardKeyPair;
pub use cks1024::VaultKeyPair;
pub use hybrid::{HybridSignature, HybridEncryptor, SecurityLevel};

/// Library version
pub const VERSION: &str = "0.2.0";

/// Generate a complete wallet with both security levels
pub fn generate_full_wallet() -> (StandardKeyPair, VaultKeyPair) {
    let standard = StandardKeyPair::generate();
    let vault = VaultKeyPair::generate();
    (standard, vault)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_full_wallet_generation() {
        let (std, vault) = generate_full_wallet();
        assert_ne!(std.spend_key, [0u8; 64]);
        assert!(vault.verify_integrity());
    }

    #[test]
    fn test_version() {
        assert_eq!(VERSION, "0.2.0");
    }
    }
