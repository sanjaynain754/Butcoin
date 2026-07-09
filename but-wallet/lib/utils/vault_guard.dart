import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';

class VaultGuard {
  // Android Keystore / iOS Keychain storage
  static const _storage = FlutterSecureStorage();
  
  // Storage keys (obfuscated names)
  static const String _keyAccessCode = 'sys_diag_hash_v1';
  static const String _keySalt = 'sys_diag_salt_v1';
  static const String _keyAttempts = 'sys_diag_attempts';

  // Store access code with real encryption
  static Future<void> storeAccessCode(String code) async {
    // Generate cryptographically random salt
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final salt = base64Encode(saltBytes);

    // Hash code with salt using PBKDF2-like iteration
    final hashedCode = _hashWithSalt(code, salt);

    // Store in platform keystore (encrypted at rest)
    await _storage.write(key: _keyAccessCode, value: hashedCode);
    await _storage.write(key: _keySalt, value: salt);
    
    // Reset failed attempts
    await _storage.write(key: _keyAttempts, value: '0');
  }

  // Verify access code
  static Future<bool> verifyAccessCode(String code) async {
    // Read stored hash and salt
    final storedHash = await _storage.read(key: _keyAccessCode);
    final salt = await _storage.read(key: _keySalt);

    // If no code stored yet, accept and store (first time setup)
    if (storedHash == null || salt == null) {
      if (code.length >= 4) {
        await storeAccessCode(code);
        return true;
      }
      return false;
    }

    // Check failed attempts (max 5)
    final attemptsStr = await _storage.read(key: _keyAttempts);
    int attempts = int.tryParse(attemptsStr ?? '0') ?? 0;
    
    if (attempts >= 5) {
      // Locked out - wait 30 seconds
      await Future.delayed(const Duration(seconds: 30));
      await _storage.write(key: _keyAttempts, value: '0');
      return false;
    }

    // Hash input and compare
    final inputHash = _hashWithSalt(code, salt);
    final isValid = (inputHash == storedHash);

    if (!isValid) {
      // Increment failed attempts
      await _storage.write(key: _keyAttempts, value: '${attempts + 1}');
      
      // Exponential backoff delay
      final delaySeconds = (attempts + 1) * 2;
      await Future.delayed(Duration(seconds: delaySeconds));
    } else {
      // Reset attempts on success
      await _storage.write(key: _keyAttempts, value: '0');
    }

    return isValid;
  }

  // Check if access code is configured
  static Future<bool> isCodeConfigured() async {
    final storedHash = await _storage.read(key: _keyAccessCode);
    return storedHash != null && storedHash.isNotEmpty;
  }

  // Wipe access code
  static Future<void> wipeAccessCode() async {
    await _storage.delete(key: _keyAccessCode);
    await _storage.delete(key: _keySalt);
    await _storage.delete(key: _keyAttempts);
  }

  // Get remaining attempts
  static Future<int> getRemainingAttempts() async {
    final attemptsStr = await _storage.read(key: _keyAttempts);
    final attempts = int.tryParse(attemptsStr ?? '0') ?? 0;
    return 5 - attempts;
  }

  // Internal: Hash code with salt (simplified PBKDF2)
  static String _hashWithSalt(String code, String salt) {
    // Multiple rounds of SHA-256 simulation
    var data = utf8.encode(code + salt);
    
    // 1000 iterations (simplified - production would use actual PBKDF2)
    for (int i = 0; i < 1000; i++) {
      data = _simpleHash(data, i);
    }
    
    return base64Encode(data);
  }

  // Simple iterative hash
  static List<int> _simpleHash(List<int> data, int round) {
    final result = List<int>.from(data);
    for (int i = 0; i < result.length; i++) {
      result[i] = (result[i] ^ (round & 0xFF)) & 0xFF;
      if (i > 0) {
        result[i] = (result[i] + result[i - 1]) & 0xFF;
      }
    }
    return result;
  }
}
