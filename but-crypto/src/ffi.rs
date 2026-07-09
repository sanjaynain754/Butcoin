// BUT Network - FFI Bridge for Flutter Integration
// Exposes C-compatible functions for Dart FFI

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::ptr;

use crate::cks512::StandardKeyPair;
use crate::cks1024::VaultKeyPair;
use crate::hybrid::{HybridSignature, SecurityLevel};

/// Generate a new 512-bit keypair and return as JSON string
/// Caller must free the returned string with `free_rust_string`
#[no_mangle]
pub extern "C" fn generate_512_keypair() -> *mut c_char {
    let pair = StandardKeyPair::generate();
    
    let json = serde_json::json!({
        "spend_key": hex::encode(pair.spend_key),
        "view_key": hex::encode(pair.view_key),
        "chain_code": hex::encode(pair.chain_code),
        "security": "512-bit",
        "status": "success"
    });

    let result = CString::new(json.to_string()).unwrap();
    result.into_raw()
}

/// Generate a new 1024-bit vault keypair and return as JSON string
#[no_mangle]
pub extern "C" fn generate_1024_keypair() -> *mut c_char {
    let pair = VaultKeyPair::generate();
    
    let json = serde_json::json!({
        "primary_key": hex::encode(pair.primary_key),
        "secondary_key": hex::encode(pair.secondary_key),
        "vault_nonce": hex::encode(pair.vault_nonce),
        "security": "1024-bit",
        "integrity": pair.verify_integrity(),
        "status": "success"
    });

    let result = CString::new(json.to_string()).unwrap();
    result.into_raw()
}

/// Derive 512-bit keys from a seed (hex encoded)
#[no_mangle]
pub extern "C" fn derive_512_from_seed(seed_hex: *const c_char) -> *mut c_char {
    if seed_hex.is_null() {
        let error = CString::new(r#"{"status":"error","message":"null seed"}"#).unwrap();
        return error.into_raw();
    }

    let seed_str = unsafe { CStr::from_ptr(seed_hex).to_string_lossy().into_owned() };
    
    let seed_bytes = match hex::decode(&seed_str) {
        Ok(bytes) if bytes.len() == 64 => {
            let mut seed = [0u8; 64];
            seed.copy_from_slice(&bytes);
            seed
        }
        _ => {
            let error = CString::new(r#"{"status":"error","message":"invalid seed"}"#).unwrap();
            return error.into_raw();
        }
    };

    let pair = StandardKeyPair::from_seed(&seed_bytes);
    
    let json = serde_json::json!({
        "spend_key": hex::encode(pair.spend_key),
        "view_key": hex::encode(pair.view_key),
        "chain_code": hex::encode(pair.chain_code),
        "security": "512-bit",
        "status": "success"
    });

    let result = CString::new(json.to_string()).unwrap();
    result.into_raw()
}

/// Sign a message using hybrid signature (512-bit)
#[no_mangle]
pub extern "C" fn sign_message_512(message: *const c_char, level: u8) -> *mut c_char {
    if message.is_null() {
        let error = CString::new(r#"{"status":"error"}"#).unwrap();
        return error.into_raw();
    }

    let msg = unsafe { CStr::from_ptr(message).to_string_lossy().into_owned() };
    
    let sec_level = match level {
        1 => SecurityLevel::Standard,
        2 => SecurityLevel::Vault,
        3 => SecurityLevel::Quantum,
        _ => SecurityLevel::Standard,
    };

    let sig = HybridSignature::new(msg.as_bytes(), sec_level);
    
    let json = serde_json::json!({
        "classical_sig": hex::encode(&sig.classical_sig),
        "quantum_sig": hex::encode(&sig.quantum_sig),
        "level": format!("{:?}", sig.level),
        "status": "success"
    });

    let result = CString::new(json.to_string()).unwrap();
    result.into_raw()
}

/// Free a string previously returned by Rust
#[no_mangle]
pub extern "C" fn free_rust_string(s: *mut c_char) {
    if s.is_null() {
        return;
    }
    unsafe {
        let _ = CString::from_raw(s);
    }
}

/// Get library version
#[no_mangle]
pub extern "C" fn get_but_crypto_version() -> *mut c_char {
    let version = CString::new("0.2.0-ffi").unwrap();
    version.into_raw()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CStr;

    #[test]
    fn test_generate_512() {
        let ptr = generate_512_keypair();
        assert!(!ptr.is_null());
        
        let json = unsafe { CStr::from_ptr(ptr).to_string_lossy().into_owned() };
        assert!(json.contains("success"));
        assert!(json.contains("512-bit"));
        
        free_rust_string(ptr);
    }

    #[test]
    fn test_generate_1024() {
        let ptr = generate_1024_keypair();
        assert!(!ptr.is_null());
        
        let json = unsafe { CStr::from_ptr(ptr).to_string_lossy().into_owned() };
        assert!(json.contains("success"));
        assert!(json.contains("1024-bit"));
        
        free_rust_string(ptr);
    }

    #[test]
    fn test_sign_message() {
        let msg = CString::new("BUT Network Test").unwrap();
        let ptr = sign_message_512(msg.as_ptr(), 1);
        assert!(!ptr.is_null());
        
        let json = unsafe { CStr::from_ptr(ptr).to_string_lossy().into_owned() };
        assert!(json.contains("success"));
        
        free_rust_string(ptr);
    }
}
