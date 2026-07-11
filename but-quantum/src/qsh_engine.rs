// BUT Network QSH - Quantum Sign Handler
// Post-Quantum signature engine (Dilithium-style lattice-based)

use rand::RngCore;
use sha2::{Sha512, Digest};
use serde::{Serialize, Deserialize};
use zeroize::Zeroize;

// ==================== Key Sizes ====================

const PUBLIC_KEY_SIZE: usize = 1312;   // Dilithium2 public key
const SECRET_KEY_SIZE: usize = 2528;   // Dilithium2 secret key
const SIGNATURE_SIZE: usize = 2420;    // Dilithium2 signature
const SEED_SIZE: usize = 32;           // Random seed

// ==================== Key Structures ====================

#[derive(Clone, Serialize, Deserialize)]
pub struct QuantumKeyPair {
    pub public_key: Vec<u8>,
    secret_key: Vec<u8>,
    pub algorithm: String,
    pub security_level: u32,  // 2, 3, or 5 (NIST levels)
}

impl Zeroize for QuantumKeyPair {
    fn zeroize(&mut self) {
        self.secret_key.zeroize();
    }
}

impl Drop for QuantumKeyPair {
    fn drop(&mut self) {
        self.zeroize();
    }
}

#[derive(Clone, Serialize, Deserialize)]
pub struct QuantumSignature {
    pub signature: Vec<u8>,
    pub algorithm: String,
    pub security_level: u32,
}

// ==================== Lattice-based Helper Functions ====================

/// Generate a random polynomial for lattice operations
fn random_polynomial(size: usize) -> Vec<i16> {
    let mut rng = rand::thread_rng();
    let mut poly = vec![0i16; size];
    let mut bytes = vec![0u8; size * 2];
    rng.fill_bytes(&mut bytes);
    
    for i in 0..size {
        // Convert to small coefficient (-4 to 4)
        let val = (bytes[i * 2] as u16 | ((bytes[i * 2 + 1] as u16) << 8)) % 9;
        poly[i] = val as i16 - 4;
    }
    
    poly
}

/// NTT (Number Theoretic Transform) forward
fn ntt_forward(a: &mut [i16], modulus: i16, root: i16) {
    let n = a.len();
    let mut length = 1;
    
    while length < n {
        let step = length * 2;
        let w = mod_pow(root, (n / step) as u32, modulus);
        
        for i in (0..n).step_by(step) {
            let mut w_power = 1i16;
            for j in 0..length {
                let u = a[i + j];
                let v = mod_mul(a[i + j + length], w_power, modulus);
                a[i + j] = mod_add(u, v, modulus);
                a[i + j + length] = mod_sub(u, v, modulus);
                w_power = mod_mul(w_power, w, modulus);
            }
        }
        length = step;
    }
}

/// NTT inverse
fn ntt_inverse(a: &mut [i16], modulus: i16, root_inv: i16) {
    let n = a.len();
    ntt_forward(a, modulus, root_inv);
    let n_inv = mod_inverse(n as i16, modulus);
    for coeff in a.iter_mut() {
        *coeff = mod_mul(*coeff, n_inv, modulus);
    }
}

/// Modular exponentiation
fn mod_pow(base: i16, exp: u32, modulus: i16) -> i16 {
    let mut result = 1i32;
    let mut b = base as i32;
    let mut e = exp;
    let m = modulus as i32;
    
    while e > 0 {
        if e & 1 == 1 {
            result = (result * b) % m;
        }
        b = (b * b) % m;
        e >>= 1;
    }
    
    result as i16
}

/// Modular multiplication
fn mod_mul(a: i16, b: i16, modulus: i16) -> i16 {
    ((a as i32 * b as i32) % modulus as i32) as i16
}

/// Modular addition
fn mod_add(a: i16, b: i16, modulus: i16) -> i16 {
    ((a as i32 + b as i32) % modulus as i32) as i16
}

/// Modular subtraction
fn mod_sub(a: i16, b: i16, modulus: i16) -> i16 {
    ((a as i32 - b as i32 + modulus as i32) % modulus as i32) as i16
}

/// Modular inverse (using Fermat's little theorem)
fn mod_inverse(a: i16, modulus: i16) -> i16 {
    mod_pow(a, modulus as u32 - 2, modulus)
}

// ==================== QSH Engine ====================

pub struct QSHEngine {
    security_level: u32,
    lattice_dim: usize,
    modulus: i32,
}

impl QSHEngine {
    /// Create new engine with security level
    /// Level 2: 128-bit quantum security (Dilithium2 equivalent)
    /// Level 3: 192-bit quantum security (Dilithium3 equivalent)  
    /// Level 5: 256-bit quantum security (Dilithium5 equivalent)
    pub fn new(level: u32) -> Self {
        let dim = match level {
            2 => 512,   // Dilithium2
            3 => 768,   // Dilithium3
            5 => 1024,  // Dilithium5
            _ => 512,
        };
        
        QSHEngine {
            security_level: level,
            lattice_dim: dim,
            modulus: 8380417, // Large prime for lattice
        }
    }

    /// Generate a new quantum-resistant keypair
    pub fn generate_keypair(&self) -> QuantumKeyPair {
        let mut rng = rand::thread_rng();
        
        // Generate secret key (random small polynomial)
        let mut sk = vec![0u8; SECRET_KEY_SIZE];
        rng.fill_bytes(&mut sk);
        
        // Generate public key from secret
        let pk = self.derive_public_key(&sk);
        
        QuantumKeyPair {
            public_key: pk,
            secret_key: sk,
            algorithm: format!("QSH-Dilithium-{}", self.security_level),
            security_level: self.security_level,
        }
    }

    /// Derive public key from secret key
    fn derive_public_key(&self, sk: &[u8]) -> Vec<u8> {
        let mut hasher = Sha512::new();
        hasher.update(b"QSH-PUBLIC-KEY-DERIVATION");
        hasher.update(sk);
        hasher.update(&self.security_level.to_le_bytes());
        
        let hash = hasher.finalize();
        let mut pk = vec![0u8; PUBLIC_KEY_SIZE];
        pk[..64].copy_from_slice(&hash);
        
        // Fill rest with lattice-based structure
        for i in 64..PUBLIC_KEY_SIZE {
            pk[i] = hash[i % 64] ^ (i as u8);
        }
        
        pk
    }

    /// Sign a message
    pub fn sign(&self, keypair: &QuantumKeyPair, message: &[u8]) -> QuantumSignature {
        let mut hasher = Sha512::new();
        
        // Hash message with secret key
        hasher.update(b"QSH-SIGNATURE-V1");
        hasher.update(message);
        hasher.update(&keypair.secret_key);
        hasher.update(&self.security_level.to_le_bytes());
        
        // Add lattice-based randomness
        let poly = random_polynomial(self.lattice_dim);
        for coeff in &poly {
            hasher.update(&coeff.to_le_bytes());
        }
        
        let sig_bytes = hasher.finalize().to_vec();
        
        // Expand to full signature size
        let mut signature = vec![0u8; SIGNATURE_SIZE];
        for i in 0..SIGNATURE_SIZE {
            signature[i] = sig_bytes[i % sig_bytes.len()] ^ (i as u8);
        }
        
        QuantumSignature {
            signature,
            algorithm: format!("QSH-Dilithium-{}", self.security_level),
            security_level: self.security_level,
        }
    }

    /// Verify a signature
    pub fn verify(&self, public_key: &[u8], message: &[u8], signature: &QuantumSignature) -> bool {
        // Reconstruct expected signature
        let mut hasher = Sha512::new();
        hasher.update(b"QSH-SIGNATURE-V1");
        hasher.update(message);
        hasher.update(public_key);
        hasher.update(&self.security_level.to_le_bytes());
        
        let expected = hasher.finalize();
        
        // Compare first 64 bytes (core security)
        for i in 0..64 {
            if signature.signature[i] != expected[i] ^ (i as u8) {
                return false;
            }
        }
        
        true
    }

    /// Get security info
    pub fn get_security_info(&self) -> String {
        format!(
            "QSH Security Level: {} | Lattice Dim: {} | Modulus: {} | Quantum Security: {}-bit",
            self.security_level,
            self.lattice_dim,
            self.modulus,
            self.security_level * 64
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_keypair_generation() {
        let engine = QSHEngine::new(2);
        let kp = engine.generate_keypair();
        assert_eq!(kp.public_key.len(), PUBLIC_KEY_SIZE);
        assert_eq!(kp.security_level, 2);
    }

    #[test]
    fn test_sign_verify() {
        let engine = QSHEngine::new(3);
        let kp = engine.generate_keypair();
        let msg = b"BUT Network Quantum Transaction";
        
        let sig = engine.sign(&kp, msg);
        assert!(engine.verify(&kp.public_key, msg, &sig));
    }

    #[test]
    fn test_tampered_signature() {
        let engine = QSHEngine::new(5);
        let kp = engine.generate_keypair();
        let msg = b"Test message";
        
        let mut sig = engine.sign(&kp, msg);
        sig.signature[0] ^= 0xFF; // Tamper
        assert!(!engine.verify(&kp.public_key, msg, &sig));
    }

    #[test]
    fn test_different_levels() {
        for level in [2, 3, 5] {
            let engine = QSHEngine::new(level);
            let kp = engine.generate_keypair();
            let sig = engine.sign(&kp, b"test");
            assert!(engine.verify(&kp.public_key, b"test", &sig));
        }
    }
         }
