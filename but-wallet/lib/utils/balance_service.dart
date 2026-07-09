// BUT Network - Balance & Transaction Service
// Handles balance tracking and transaction processing

import 'dart:math';

class BalanceService {
  // Simulated balance storage
  static int _balanceBites = 0;
  static final List<Map<String, dynamic>> _transactions = [];
  static bool _initialized = false;

  // Initialize with some test balance
  static Future<void> initialize() async {
    if (_initialized) return;

    // Simulate loading from storage
    await Future.delayed(const Duration(milliseconds: 500));

    // Give some test balance for demo
    _balanceBites = 500000; // 500 BUT = 500,000 Bites
    _initialized = true;
  }

  // Get balance in Bites
  static Future<int> getBalance() async {
    if (!_initialized) await initialize();
    return _balanceBites;
  }

  // Get balance in BUT (formatted)
  static Future<String> getFormattedBalance() async {
    final bites = await getBalance();
    final but = bites / 1000.0;
    return '${but.toStringAsFixed(3)} BUT';
  }

  // Get balance in both units
  static Future<Map<String, dynamic>> getBalanceDetails() async {
    final bites = await getBalance();
    return {
      'bites': bites,
      'but': bites / 1000.0,
      'formatted': '${(bites / 1000.0).toStringAsFixed(3)} BUT',
      'bites_formatted': '$bites Bites',
    };
  }

  // Calculate fee for transaction
  static int calculateFee(int amountBites, {String txType = 'standard'}) {
    switch (txType) {
      case 'vault':
        return max(5, amountBites ~/ 500);
      case 'contract':
        return max(10, amountBites ~/ 200);
      case 'name':
        return 50;
      case 'recovery':
        return 100;
      default: // standard
        return max(1, amountBites ~/ 1000);
    }
  }

  // Send transaction
  static Future<bool> sendTransaction(
    String address,
    int amountBites,
    int feeBites,
    String note,
  ) async {
    if (!_initialized) await initialize();

    final total = amountBites + feeBites;
    if (_balanceBites < total) return false;

    // Deduct balance
    _balanceBites -= total;

    // Record transaction
    _transactions.insert(0, {
      'id': 'TX-${DateTime.now().millisecondsSinceEpoch}',
      'type': 'send',
      'address': address,
      'amount': amountBites,
      'fee': feeBites,
      'total': total,
      'note': note,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'completed',
    });

    return true;
  }

  // Receive transaction (simulated)
  static Future<void> receiveTransaction(
    String from,
    int amountBites,
  ) async {
    if (!_initialized) await initialize();

    _balanceBites += amountBites;

    _transactions.insert(0, {
      'id': 'TX-${DateTime.now().millisecondsSinceEpoch}',
      'type': 'receive',
      'address': from,
      'amount': amountBites,
      'fee': 0,
      'total': amountBites,
      'note': '',
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'completed',
    });
  }

  // Get transaction history
  static Future<List<Map<String, dynamic>>> getTransactions({
    int limit = 20,
  }) async {
    if (!_initialized) await initialize();
    return _transactions.take(limit).toList();
  }

  // Get transaction count
  static Future<int> getTransactionCount() async {
    if (!_initialized) await initialize();
    return _transactions.length;
  }

  // Clear all data (for testing)
  static Future<void> reset() async {
    _balanceBites = 0;
    _transactions.clear();
    _initialized = false;
  }
}
