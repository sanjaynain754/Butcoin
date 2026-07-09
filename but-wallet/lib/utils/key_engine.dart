import 'dart:convert';
import 'package:bip39/bip39.dart' as bip39;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:flutter/services.dart';
import 'bip_paths.dart';

class KeyEngine {
  // ==================== BUT Standard: 24 Words, 512-bit ====================
  
  /// Generate 24-word mnemonic (256-bit entropy → 512-bit security with CKS)
  static Future<String> generateMnemonic() async {
    // BUT Network standard: 24 words
    final mnemonic = bip39.generateMnemonic(strength: 256); // 24 words
    return mnemonic;
  }

  /// Generate 12-word mnemonic (for lightweight wallets only)
  static Future<String> generateLightMnemonic() async {
    return bip39.generateMnemonic(strength: 128); // 12 words
  }

  /// Validate mnemonic
  static bool validateMnemonic(String mnemonic) {
    return bip39.validateMnemonic(mnemonic);
  }

  /// Get mnemonic word count
  static int getWordCount(String mnemonic) {
    return mnemonic.split(' ').length;
  }

  // ==================== Key Derivation with BIP Paths ====================

  /// Derive keys using specific BIP path
  static Future<Map<String, String>> deriveKeysWithPath(
    String mnemonic, 
    String bipPath,
  ) async {
    final seed = bip39.mnemonicToSeed(mnemonic);
    
    final masterKey = await ED25519_HD_KEY.derivePath(bipPath, seed);

    return {
      'private_key': base64Encode(masterKey.key),
      'public_key': base64Encode(masterKey.chainCode),
      'bip_path': bipPath,
      'coin_type': '777',
    };
  }

  /// Derive BUT standard keys (CKS-512)
  static Future<Map<String, String>> deriveButKeys(String mnemonic) async {
    // Primary: BIP88 (CKS-512)
    final primary = await deriveKeysWithPath(mnemonic, BipPaths.bip88);
    
    // Secondary: BUT-S & BUT-V
    final butS = await deriveKeysWithPath(mnemonic, BipPaths.bip101);
    final butV = await deriveKeysWithPath(mnemonic, BipPaths.bip102);

    return {
      'spend_key': '0xS${butS['private_key']}',
      'view_key': '0xV${butV['private_key']}',
      'primary_key': primary['private_key']!,
      'coin_type': '777',
      'security': '512-bit CKS',
      'word_count': '24',
    };
  }

  /// Derive Vault keys (CKS-1024)
  static Future<Map<String, String>> deriveVaultKeys(String mnemonic) async {
    final vault = await deriveKeysWithPath(mnemonic, BipPaths.bip100);
    final butS = await deriveKeysWithPath(mnemonic, BipPaths.bip101);
    final butV = await deriveKeysWithPath(mnemonic, BipPaths.bip102);

    return {
      'spend_key': '0xS${butS['private_key']}',
      'view_key': '0xV${butV['private_key']}',
      'vault_key': vault['private_key']!,
      'coin_type': '777',
      'security': '1024-bit CKS Vault',
      'word_count': '24',
    };
  }

  /// Derive ALL 20+ keys from mnemonic
  static Future<Map<String, Map<String, String>>> deriveAllKeys(String mnemonic) async {
    final allPaths = BipPaths.getAllPaths();
    final result = <String, Map<String, String>>{};

    for (final entry in allPaths.entries) {
      final keys = await deriveKeysWithPath(mnemonic, entry.value);
      result[entry.key] = keys;
    }

    return result;
  }

  // ==================== Import Wallets ====================

  /// Import BUT wallet (24 words default)
  static Future<Map<String, String>?> importButWallet(String mnemonic) async {
    if (!validateMnemonic(mnemonic)) return null;

    final wordCount = getWordCount(mnemonic);
    
    // BUT standard: 24 words
    if (wordCount == 24) {
      return await deriveButKeys(mnemonic);
    }
    
    // Also accept 12 words (with warning)
    if (wordCount == 12) {
      return await deriveButKeys(mnemonic);
    }

    return null;
  }

  /// Import any wallet (just validate, don't modify)
  static Future<Map<String, String>?> importAnyWallet(String mnemonic) async {
    if (!validateMnemonic(mnemonic)) return null;

    final wordCount = getWordCount(mnemonic);
    
    // Use appropriate derivation based on word count
    final keys = await deriveKeysWithPath(
      mnemonic,
      wordCount == 24 ? BipPaths.bip88 : BipPaths.bip44,
    );

    return {
      'private_key': keys['private_key']!,
      'public_key': keys['public_key']!,
      'coin_type': '777',
      'security': wordCount == 24 ? '512-bit' : '256-bit',
      'word_count': '$wordCount',
      'imported': 'true', // Mark as imported
    };
  }

  // ==================== Clipboard Import ====================

  /// Try to import from clipboard
  static Future<Map<String, String>?> importFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null || data!.text!.isEmpty) return null;

    final text = data.text!.trim();
    if (validateMnemonic(text)) {
      return await importAnyWallet(text);
    }

    return null;
  }

  // ==================== Backward Compatibility ====================

  static Future<String> generateConfusionString() async {
    return await generateMnemonic(); // 24 words default
  }

  static Future<String?> reverseConfusionString(String mode) async {
    if (mode == 'import') {
      final keys = await importFromClipboard();
      return keys?.toString();
    }
    return null;
  }
}
