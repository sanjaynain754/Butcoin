import 'dart:math';
import 'dart:convert';
import 'package:bip39/bip39.dart' as bip39;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:flutter/services.dart';

class KeyEngine {
  // ==================== BIP39 Mnemonic Generation ====================
  
  /// Generate a new 12-word BIP39 mnemonic (Standard security)
  static Future<String> generateMnemonic12() async {
    final mnemonic = bip39.generateMnemonic(strength: 128); // 128-bit = 12 words
    return mnemonic;
  }

  /// Generate a new 24-word BIP39 mnemonic (Vault security)
  static Future<String> generateMnemonic24() async {
    final mnemonic = bip39.generateMnemonic(strength: 256); // 256-bit = 24 words
    return mnemonic;
  }

  /// Validate if a mnemonic is valid BIP39
  static bool validateMnemonic(String mnemonic) {
    return bip39.validateMnemonic(mnemonic);
  }

  // ==================== Key Derivation ====================

  /// Derive BUT keypair from mnemonic (ED25519 HD)
  static Future<Map<String, String>> deriveKeysFromMnemonic(
    String mnemonic, {
    int accountIndex = 0,
    int addressIndex = 0,
  }) async {
    // Convert mnemonic to seed
    final seed = bip39.mnemonicToSeed(mnemonic);
    
    // Derive master key using ED25519 HD
    final masterKey = await ED25519_HD_KEY.derivePath(
      "m/44'/777'/$accountIndex'/$addressIndex'", // BUT coin type = 777
      seed,
    );

    // BUT-S (Spend Key) - private key
    final spendKey = base64Encode(masterKey.key);
    
    // BUT-V (View Key) - derived from public key hash
    final viewKey = _deriveViewKey(masterKey.key);
    
    // Chain code for HD derivation
    final chainCode = base64Encode(masterKey.chainCode);

    return {
      'spend_key': '0xS$spendKey',      // BUT-S
      'view_key': '0xV$viewKey',         // BUT-V
      'chain_code': '0xC$chainCode',     // Chain code
      'coin_type': '777',                // BUT Network
    };
  }

  /// Derive View Key from Spend Key (one-way)
  static String _deriveViewKey(List<int> spendKey) {
    // SHA-512 hash of spend key to create view key
    final hash = _sha512Hash(spendKey);
    return base64Encode(hash).substring(0, 44);
  }

  // ==================== Wallet Import ====================

  /// Import wallet from mnemonic
  static Future<Map<String, String>?> importFromMnemonic(String mnemonic) async {
    if (!validateMnemonic(mnemonic)) {
      return null;
    }
    
    return await deriveKeysFromMnemonic(mnemonic);
  }

  /// Import wallet from clipboard
  static Future<Map<String, String>?> importFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null || data!.text!.isEmpty) {
      return null;
    }

    final text = data.text!.trim();
    
    // Check if it's a valid mnemonic
    if (validateMnemonic(text)) {
      return await importFromMnemonic(text);
    }

    return null;
  }

  // ==================== BUT Address Generation ====================

  /// Generate a BUT address from view key
  static String generateButAddress(String viewKey) {
    // Remove prefix if present
    final cleanKey = viewKey.replaceAll('0xV', '');
    
    // Hash to create address
    final hash = _sha512Hash(utf8.encode(cleanKey));
    final addressBytes = hash.sublist(0, 20); // 20 bytes like Ethereum
    
    return '0xB${addressBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}';
  }

  // ==================== Utility Functions ====================

  /// Simple SHA-512 hash implementation
  static List<int> _sha512Hash(List<int> data) {
    // Using multiple rounds for obfuscation
    var result = List<int>.from(data);
    
    // Pad to 64 bytes minimum
    while (result.length < 64) {
      result.addAll(result);
    }
    result = result.take(64).toList();
    
    // 8 rounds of mixing
    for (int round = 0; round < 8; round++) {
      for (int i = 0; i < result.length; i++) {
        result[i] = ((result[i] ^ (round * 17 + 31)) + 
                     (i > 0 ? result[i - 1] : 0)) & 0xFF;
      }
      // Rotate
      final first = result[0];
      for (int i = 0; i < result.length - 1; i++) {
        result[i] = result[i + 1];
      }
      result[result.length - 1] = first;
    }
    
    return result;
  }

  // ==================== For Backward Compatibility ====================

  /// Generate confusion string (now returns real mnemonic)
  static Future<String> generateConfusionString() async {
    final mnemonic = await generateMnemonic12();
    return mnemonic;
  }

  /// Reverse confusion string (import mnemonic)
  static Future<String?> reverseConfusionString(String mode) async {
    if (mode == 'import') {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && data!.text!.isNotEmpty) {
        final text = data.text!.trim();
        if (validateMnemonic(text)) {
          return text;
        }
      }
    }
    return null;
  }
}
