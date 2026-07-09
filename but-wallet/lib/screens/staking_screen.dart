import 'package:flutter/material.dart';
import '../utils/staking_engine.dart';
import '../utils/balance_service.dart';

class StakingScreen extends StatefulWidget {
  const StakingScreen({super.key});

  @override
  State<StakingScreen> createState() => _StakingScreenState();
}

class _StakingScreenState extends State<StakingScreen> {
  final _amountController = TextEditingController();
  String _selectedPeriod = '30 days';
  bool _isStaking = false;
  String? _status;
  List<Map<String, dynamic>> _activeStakes = [];

  final Map<String, double> _apyRates = {
    '30 days': 5.0,
    '90 days': 8.0,
    '180 days': 12.0,
    '365 days': 20.0,
  };

  @override
  void initState() {
    super.initState();
    _loadStakes();
  }

  void _loadStakes() async {
    final stakes = await StakingEngine.getActiveStakes();
    setState(() {
      _activeStakes = stakes;
    });
  }

  void _stakeTokens() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      setState(() => _status = 'Error: Enter valid amount');
      return;
    }

    setState(() {
      _isStaking = true;
      _status = null;
    });

    final result = await StakingEngine.stakeTokens(
      amount: amount,
      period: _selectedPeriod,
      apy: _apyRates[_selectedPeriod]!,
    );

    setState(() {
      _isStaking = false;
      if (result['success'] == true) {
        _status = 'Success: ${amount.toStringAsFixed(3)} BUT staked!';
        _amountController.clear();
        _loadStakes();
      } else {
        _status = 'Error: ${result['error']}';
      }
    });
  }

  void _unstakeTokens(String stakeId) async {
    final result = await StakingEngine.unstakeTokens(stakeId);
    setState(() {
      if (result['success'] == true) {
        _status = 'Success: Unstaked with reward!';
      } else {
        _status = 'Error: ${result['error']}';
      }
      _loadStakes();
    });
  }

  double _calculateReward(double amount, double apy, String period) {
    final days = int.parse(period.split(' ')[0]);
    return amount * (apy / 100) * (days / 365);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staking'),
        backgroundColor: Colors.amber[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stake Form
            Card(
              color: Colors.grey[850],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stake BUT Tokens',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 16),

                    // Amount
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount (BUT)',
                        hintText: '0.000',
                        prefixIcon: Icon(Icons.currency_bitcoin),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Period Selection
                    const Text('Lock Period:', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _selectedPeriod,
                      dropdownColor: Colors.grey[800],
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      isExpanded: true,
                      items: _apyRates.keys.map((period) {
                        return DropdownMenuItem(
                          value: period,
                          child: Text('$period (${_apyRates[period]}% APY)'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedPeriod = val!),
                    ),
                    const SizedBox(height: 12),

                    // Reward Preview
                    if (_amountController.text.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[900],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Estimated Reward: ${_calculateReward(double.tryParse(_amountController.text) ?? 0, _apyRates[_selectedPeriod]!, _selectedPeriod).toStringAsFixed(3)} BUT',
                          style: const TextStyle(color: Colors.greenAccent),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Stake Button
                    ElevatedButton.icon(
                      onPressed: _isStaking ? null : _stakeTokens,
                      icon: _isStaking
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.lock),
                      label: Text(_isStaking ? 'Staking...' : 'Stake Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Status
            if (_status != null) ...[
              const SizedBox(height: 16),
              Card(
                color: _status!.startsWith('Error') ? Colors.red[900] : Colors.green[900],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(_status!, style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Active Stakes
            if (_activeStakes.isNotEmpty) ...[
              const Text(
                'Active Stakes',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              ..._activeStakes.map((stake) {
                return Card(
                  color: Colors.grey[800],
                  child: ListTile(
                    leading: const Icon(Icons.lock, color: Colors.amber),
                    title: Text(
                      '${stake['amount']} BUT',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'APY: ${stake['apy']}% | Until: ${stake['unlock_date']}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _unstakeTokens(stake['id']),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
                      child: const Text('Unstake'),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
