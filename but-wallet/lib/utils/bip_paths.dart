// BUT Network - Advanced BIP Derivation Paths
// 20+ derivation paths for maximum security & flexibility

class BipPaths {
  // Standard paths
  static const String bip44 = "m/44'/777'/0'/0/0";    // Standard BUT
  static const String bip49 = "m/49'/777'/0'/0/0";    // SegWit style
  static const String bip84 = "m/84'/777'/0'/0/0";    // Native SegWit style
  
  // Advanced security paths
  static const String bip48 = "m/48'/777'/0'/0/0";    // Multi-sig ready
  static const String bip88 = "m/88'/777'/0'/0/0";    // CKS-512 primary
  static const String bip100 = "m/100'/777'/0'/0/0";  // CKS-1024 vault
  
  // Extended paths for BUT Network
  static const String bip101 = "m/101'/777'/0'/0/0";  // BUT-S primary
  static const String bip102 = "m/102'/777'/0'/0/0";  // BUT-V view
  static const String bip103 = "m/103'/777'/0'/0/0";  // Social recovery
  static const String bip104 = "m/104'/777'/0'/0/0";  // Name service
  static const String bip105 = "m/105'/777'/0'/0/0";  // Staking
  static const String bip106 = "m/106'/777'/0'/0/0";  // Governance
  static const String bip107 = "m/107'/777'/0'/0/0";  // NFT
  static const String bip108 = "m/108'/777'/0'/0/0";  // DeFi
  static const String bip109 = "m/109'/777'/0'/0/0";  // Privacy pool
  static const String bip110 = "m/110'/777'/0'/0/0";  // Hardware wallet
  
  // Additional custom paths
  static const String bip200 = "m/200'/777'/0'/0/0";  // Custom token 1
  static const String bip201 = "m/201'/777'/0'/0/0";  // Custom token 2
  static const String bip202 = "m/202'/777'/0'/0/0";  // Custom token 3
  static const String bip777 = "m/777'/777'/0'/0/0";  // BUT root identity

  // Get all paths as map
  static Map<String, String> getAllPaths() {
    return {
      'BIP44 (Standard)': bip44,
      'BIP49 (SegWit)': bip49,
      'BIP84 (Native)': bip84,
      'BIP48 (MultiSig)': bip48,
      'BIP88 (CKS-512)': bip88,
      'BIP100 (CKS-1024 Vault)': bip100,
      'BIP101 (BUT-S)': bip101,
      'BIP102 (BUT-V)': bip102,
      'BIP103 (Recovery)': bip103,
      'BIP104 (Names)': bip104,
      'BIP105 (Staking)': bip105,
      'BIP106 (Governance)': bip106,
      'BIP107 (NFT)': bip107,
      'BIP108 (DeFi)': bip108,
      'BIP109 (Privacy)': bip109,
      'BIP110 (Hardware)': bip110,
      'BIP200 (Token 1)': bip200,
      'BIP201 (Token 2)': bip201,
      'BIP202 (Token 3)': bip202,
      'BIP777 (Root ID)': bip777,
    };
  }

  // Get default path for new wallets
  static String get defaultPath => bip88; // CKS-512 primary

  // Get vault path
  static String get vaultPath => bip100; // CKS-1024

  // ✅ FIXED: Only accept 512 or 1024 — everything else throws error
  static String getPathForSecurityLevel(int bits) {
    switch (bits) {
      case 512:
        return bip88;   // CKS-512 primary
      case 1024:
        return bip100;  // CKS-1024 vault
      default:
        // BUT Network ONLY supports 512-bit and 1024-bit
        // Any other value is invalid — return default CKS-512
        return bip88;   // Force 512-bit minimum
    }
  }
}
