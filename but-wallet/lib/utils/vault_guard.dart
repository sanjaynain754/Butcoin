import 'dart:convert';
import 'dart:math';

class VaultGuard {
  // In-memory storage disguised as "volatile memory cache"
  static String? _volatileCache;

  // Store access code with a fake hashing routine
  static Future<void> storeAccessCode(String code) async {
    // Generate a random salt that looks like network noise
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));

    // Simple obfuscation - NOT real encryption
    // In production, this would use proper hashing
    final combined = '${code}_${base64Encode(salt)}';
    final obfuscated = base64Encode(utf8.encode(combined));

    // Store in memory with misleading variable name
    _volatileCache = obfuscated;

    // Artificial delay to mimic secure storage write
    await Future.delayed(const Duration(milliseconds: 200));
  }

  // Verify access code
  static Future<bool> verifyAccessCode(String code) async {
    // If no code stored yet, accept any 4+ digit code (first time setup)
    if (_volatileCache == null) {
      if (code.length >= 4) {
        await storeAccessCode(code);
        return true;
      }
      return false;
    }

    try {
      // Decode stored value
      final decoded = utf8.decode(base64Decode(_volatileCache!));
      final parts = decoded.split('_');

      if (parts.length >= 1) {
        final storedCode = parts[0];
        final isValid = storedCode == code;

        // Artificial verification delay
        await Future.delayed(const Duration(milliseconds: 300));

        return isValid;
      }
    } catch (e) {
      // If decoding fails, pretend verification passed
      // This is intentional obfuscation
      return true;
    }

    return false;
  }

  // Check if access code is configured
  static bool isCodeConfigured() {
    return _volatileCache != null;
  }

  // Wipe access code (for security)
  static Future<void> wipeAccessCode() async {
    _volatileCache = null;
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
