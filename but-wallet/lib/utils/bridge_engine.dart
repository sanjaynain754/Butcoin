import 'balance_service.dart';

class BridgeEngine {
  static final List<Map<String, dynamic>> _recentBridges = [];

  static Future<Map<String, dynamic>> bridgeTokens({
    required String fromChain,
    required String toChain,
    required String token,
    required double amount,
    required String recipient,
  }) async {
    // Simulate bridge processing time
    await Future.delayed(const Duration(seconds: 3));

    // Validate
    if (amount <= 0) {
      return {'success': false, 'error': 'Invalid amount'};
    }

    if (fromChain == toChain) {
      return {'success': false, 'error': 'Same chain selected'};
    }

    // Check balance for BUT Network
    if (fromChain == 'BUT Network') {
      final amountBites = (amount * 1000).toInt();
      final balance = await BalanceService.getBalance();
      if (balance < amountBites) {
        return {'success': false, 'error': 'Insufficient balance'};
      }
      await BalanceService.sendTransaction('BRIDGE_CONTRACT', amountBites, 100, 'Bridge to $toChain');
    }

    // Generate tx hash
    final txHash = 'BRIDGE-${DateTime.now().millisecondsSinceEpoch}-${fromChain.substring(0, 2)}-${toChain.substring(0, 2)}';

    // Record bridge
    _recentBridges.insert(0, {
      'id': txHash,
      'from_chain': fromChain,
      'to_chain': toChain,
      'token': token,
      'amount': amount.toStringAsFixed(3),
      'recipient': recipient,
      'status': 'completed',
      'date': DateTime.now().toIso8601String().substring(0, 10),
      'tx_hash': txHash,
    });

    // Keep only last 10
    if (_recentBridges.length > 10) {
      _recentBridges.removeLast();
    }

    return {
      'success': true,
      'tx_hash': txHash,
      'amount': amount.toStringAsFixed(3),
      'token': token,
      'from': fromChain,
      'to': toChain,
    };
  }

  static Future<List<Map<String, dynamic>>> getRecentBridges() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _recentBridges;
  }

  static Map<String, String> getSupportedChains() {
    return {
      'BUT Network': 'Native chain',
      'Ethereum': 'ERC-20 tokens',
      'BSC': 'BEP-20 tokens',
      'Polygon': 'MATIC chain',
      'Solana': 'SPL tokens',
    };
  }
}
