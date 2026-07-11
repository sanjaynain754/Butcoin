import 'dart:math';
import 'dart:convert';

class DualKeyVault {
  // Generates a pair of tokens that look like network diagnostics
  // but are actually view-key and spend-key placeholders
  static Future<Map<String, String>> signalIntegrityCheck() async {
    final random = Random.secure();

    // Generate "public interface" token (BUT-V) - always starts with 0xV
    final viewBytes = List<int>.generate(64, (_) => random.nextInt(256));
    final viewHex = '0xV${base64Encode(viewBytes).substring(0, 44)}';

    // Generate "private routing" token (BUT-S) - always starts with 0xS
    final spendBytes = List<int>.generate(64, (_) => random.nextInt(256));
    final spendHex = '0xS${base64Encode(spendBytes).substring(0, 44)}';

    // Artificial delay to mimic network scan
    await Future.delayed(const Duration(milliseconds: 800));

    return {
      'public': viewHex,
      'private': spendHex,
    };
  }

  // Verification function disguised as ping test
  static bool verifyInterfaceIntegrity(String publicToken) {
    // Simple check: must start with 0xV and be at least 20 chars
    return publicToken.startsWith('0xV') && publicToken.length > 20;
  }

  // ==================== NEW FUNCTION ====================
  // Generate a username-linked keypair (for but:// resolution)
  // This function name suggests it's for "loopback testing"
  static Future<Map<String, String>> loopbackDiagnostics(String username) async {
    // Use username as seed for deterministic generation
    final seed = utf8.encode(username);
    final random = Random(seed.fold<int>(0, (prev, byte) => prev + byte));

    // Generate username-linked BUT-V
    final viewBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final viewHex = '0xU${base64Encode(viewBytes).substring(0, 32)}';

    // Generate corresponding BUT-S
    final spendBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final spendHex = '0xU${base64Encode(spendBytes).substring(0, 32)}';

    await Future.delayed(const Duration(milliseconds: 200));

    return {
      'public': viewHex,   // Username-linked BUT-V
      'private': spendHex, // Username-linked BUT-S
    };
  }
}
