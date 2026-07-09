import 'balance_service.dart';

class SwapEngine {
  static final Map<String, double> _rates = {
    'BUT-BUTTER': 10.0,
    'BUT-GOLD': 0.5,
    'BUT-SILVER': 50.0,
    'BUTTER-BUT': 0.1,
    'GOLD-BUT': 2.0,
    'SILVER-BUT': 0.02,
  };

  static double getExchangeRate(String from, String to) {
    final key = '$from-$to';
    return _rates[key] ?? 1.0;
  }

  static Future<Map<String, dynamic>> executeSwap({
    required String fromToken,
    required String toToken,
    required double amount,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    final rate = getExchangeRate(fromToken, toToken);
    final received = amount * rate;
    final fee = amount * 0.001; // 0.1% fee

    // Check balance (simplified)
    final balance = await BalanceService.getBalance();
    final amountBites = (amount * 1000).toInt();
    
    if (balance < amountBites) {
      return {'success': false, 'error': 'Insufficient balance'};
    }

    return {
      'success': true,
      'received': received.toStringAsFixed(3),
      'rate': rate,
      'fee': fee.toStringAsFixed(3),
      'tx_id': 'SWAP-${DateTime.now().millisecondsSinceEpoch}',
    };
  }
}
