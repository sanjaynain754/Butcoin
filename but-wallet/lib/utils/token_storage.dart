import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'but_custom_tokens_v1';
  static List<Map<String, dynamic>> _cache = [];
  static bool _loaded = false;

  // Load tokens from secure storage
  static Future<List<Map<String, dynamic>>> getAllTokens() async {
    if (_loaded) return _cache;

    try {
      final data = await _storage.read(key: _tokenKey);
      if (data != null && data.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(data);
        _cache = decoded.cast<Map<String, dynamic>>();
      } else {
        // Add some default tokens for demo
        _cache = _getDefaultTokens();
        await _saveToStorage();
      }
      _loaded = true;
    } catch (e) {
      _cache = _getDefaultTokens();
      _loaded = true;
    }

    return _cache;
  }

  // Save a single token
  static Future<void> saveToken(Map<String, dynamic> token) async {
    if (!_loaded) await getAllTokens();
    
    // Check for duplicate
    final existing = _cache.indexWhere((t) => t['token_id'] == token['token_id']);
    if (existing >= 0) {
      _cache[existing] = token;
    } else {
      _cache.insert(0, token);
    }

    await _saveToStorage();
  }

  // Delete a token
  static Future<void> deleteToken(String tokenId) async {
    if (!_loaded) await getAllTokens();
    _cache.removeWhere((t) => t['token_id'] == tokenId);
    await _saveToStorage();
  }

  // Save to secure storage
  static Future<void> _saveToStorage() async {
    final json = jsonEncode(_cache);
    await _storage.write(key: _tokenKey, value: json);
  }

  // Default tokens for demo
  static List<Map<String, dynamic>> _getDefaultTokens() {
    return [
      {
        'token_id': 'BUT-BTC-001',
        'name': 'Butter Token',
        'symbol': 'BUTTER',
        'total_supply': 10000000,
        'decimals': 3,
        'tier': 'featured',
        'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        'owner': 'system',
        'verified': true,
        'featured': true,
      },
      {
        'token_id': 'BUT-GOLD-002',
        'name': 'Gold Coin',
        'symbol': 'GOLD',
        'total_supply': 21000000,
        'decimals': 6,
        'tier': 'verified',
        'created_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
        'owner': 'user_demo',
        'verified': true,
        'featured': false,
      },
    ];
  }

  // Clear all (testing)
  static Future<void> clearAll() async {
    _cache.clear();
    await _storage.delete(key: _tokenKey);
    _loaded = false;
  }
}
