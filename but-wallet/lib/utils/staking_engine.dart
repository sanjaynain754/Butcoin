import 'balance_service.dart';

class StakingEngine {
  static final List<Map<String, dynamic>> _stakes = [];

  static Future<Map<String, dynamic>> stakeTokens({
    required double amount,
    required String period,
    required double apy,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    final amountBites = (amount * 1000).toInt();
    final balance = await BalanceService.getBalance();

    if (balance < amountBites) {
      return {'success': false, 'error': 'Insufficient balance'};
    }

    // Deduct balance
    await BalanceService.sendTransaction('STAKING_CONTRACT', amountBites, 10, 'Stake');

    // Calculate unlock date
    final days = int.parse(period.split(' ')[0]);
    final unlockDate = DateTime.now().add(Duration(days: days));

    final stakeData = {
      'id': 'STAKE-${DateTime.now().millisecondsSinceEpoch}',
      'amount': amount.toStringAsFixed(3),
      'period': period,
      'apy': apy,
      'unlock_date': unlockDate.toIso8601String().substring(0, 10),
      'reward': (amount * (apy / 100) * (days / 365)).toStringAsFixed(3),
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    };

    _stakes.add(stakeData);

    return {'success': true, 'stake_data': stakeData};
  }

  static Future<Map<String, dynamic>> unstakeTokens(String stakeId) async {
    await Future.delayed(const Duration(seconds: 1));

    final index = _stakes.indexWhere((s) => s['id'] == stakeId);
    if (index < 0) {
      return {'success': false, 'error': 'Stake not found'};
    }

    final stake = _stakes[index];
    final amount = double.parse(stake['amount']);
    final reward = double.parse(stake['reward']);
    final total = amount + reward;

    // Return tokens
    final totalBites = (total * 1000).toInt();
    await BalanceService.receiveTransaction('STAKING_REWARD', totalBites);

    _stakes.removeAt(index);

    return {
      'success': true,
      'returned': total.toStringAsFixed(3),
      'reward': reward.toStringAsFixed(3),
    };
  }

  static Future<List<Map<String, dynamic>>> getActiveStakes() async {
    return _stakes.where((s) => s['status'] == 'active').toList();
  }

  static double calculateTotalStaked() {
    double total = 0;
    for (final stake in _stakes) {
      if (stake['status'] == 'active') {
        total += double.parse(stake['amount']);
      }
    }
    return total;
  }
}
