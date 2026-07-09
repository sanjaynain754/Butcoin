import 'package:flutter/material.dart';
import 'token_storage.dart';

enum TokenTier { basic, verified, featured }

class TokenManager {
  // Tier information
  static Map<String, dynamic> getTierInfo(TokenTier tier) {
    switch (tier) {
      case TokenTier.basic:
        return {
          'name': 'Basic (Free)',
          'price': 'Free - 100 Bites network fee',
          'icon': Icons.star_border,
          'color': Colors.grey,
          'fee_bites': 100,
        };
      case TokenTier.verified:
        return {
          'name': 'Verified (₹999)',
          'price': '₹999 + 500 Bites network fee',
          'icon': Icons.verified,
          'color': Colors.blue,
          'fee_bites': 500,
        };
      case TokenTier.featured:
        return {
          'name': 'Featured (₹12,999)',
          'price': '₹12,999 + 1000 Bites network fee',
          'icon': Icons.diamond,
          'color': Colors.amber,
          'fee_bites': 1000,
        };
    }
  }

  // Create a new token
  static Future<Map<String, dynamic>> createToken({
    required String name,
    required String symbol,
    required int totalSupply,
    required int decimals,
    required TokenTier tier,
  }) async {
    // Simulate network processing
    await Future.delayed(const Duration(seconds: 2));

    // Validate
    if (name.length < 2 || name.length > 32) {
      return {'success': false, 'error': 'Name must be 2-32 characters'};
    }
    if (symbol.length < 1 || symbol.length > 8) {
      return {'success': false, 'error': 'Symbol must be 1-8 characters'};
    }
    if (totalSupply < 1 || totalSupply > 1000000000000) {
      return {'success': false, 'error': 'Supply must be 1-1T'};
    }
    if (decimals < 0 || decimals > 18) {
      return {'success': false, 'error': 'Decimals must be 0-18'};
    }

    // Generate token ID
    final tokenId = 'BUT-${symbol.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}';

    // Create token data
    final tokenData = {
      'token_id': tokenId,
      'name': name,
      'symbol': symbol.toUpperCase(),
      'total_supply': totalSupply,
      'decimals': decimals,
      'tier': tier.name,
      'created_at': DateTime.now().toIso8601String(),
      'owner': 'current_user', // Would be actual user address
      'verified': tier != TokenTier.basic,
      'featured': tier == TokenTier.featured,
    };

    // Save token
    await TokenStorage.saveToken(tokenData);

    return {
      'success': true,
      'token_id': tokenId,
      'token_data': tokenData,
    };
  }

  // Get all tokens
  static Future<List<Map<String, dynamic>>> getAllTokens() async {
    return await TokenStorage.getAllTokens();
  }

  // Get user's tokens
  static Future<List<Map<String, dynamic>>> getUserTokens() async {
    final all = await TokenStorage.getAllTokens();
    return all.where((t) => t['owner'] == 'current_user').toList();
  }

  // Get featured tokens
  static Future<List<Map<String, dynamic>>> getFeaturedTokens() async {
    final all = await TokenStorage.getAllTokens();
    return all.where((t) => t['featured'] == true).toList();
  }

  // Get verified tokens
  static Future<List<Map<String, dynamic>>> getVerifiedTokens() async {
    final all = await TokenStorage.getAllTokens();
    return all.where((t) => t['verified'] == true).toList();
  }

  // Search token by name or symbol
  static Future<List<Map<String, dynamic>>> searchTokens(String query) async {
    final all = await TokenStorage.getAllTokens();
    final lower = query.toLowerCase();
    return all.where((t) {
      return t['name'].toLowerCase().contains(lower) ||
             t['symbol'].toLowerCase().contains(lower);
    }).toList();
  }
}
