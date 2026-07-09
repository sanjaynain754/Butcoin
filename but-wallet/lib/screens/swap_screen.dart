import 'package:flutter/material.dart';
import '../utils/swap_engine.dart';
import '../utils/balance_service.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  final _amountController = TextEditingController();
  String _fromToken = 'BUT';
  String _toToken = 'BUTTER';
  double _exchangeRate = 10.0;
  bool _isSwapping = false;
  String? _status;

  final List<String> _availableTokens = ['BUT', 'BUTTER', 'GOLD', 'SILVER'];

  void _calculateSwap() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final received = amount * _exchangeRate;
    
    setState(() {
      _status = 'You will receive: ${received.toStringAsFixed(3)} $_toToken';
    });
  }

  void _executeSwap() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      setState(() => _status = 'Error: Enter valid amount');
      return;
    }

    setState(() {
      _isSwapping = true;
      _status = null;
    });

    final result = await SwapEngine.executeSwap(
      fromToken: _fromToken,
      toToken: _toToken,
      amount: amount,
    );

    setState(() {
      _isSwapping = false;
      if (result['success'] == true) {
        _status = 'Success: Swapped ${amount.toStringAsFixed(3)} $_fromToken to ${result['received']} $_toToken';
        _amountController.clear();
      } else {
        _status = 'Error: ${result['error']}';
      }
    });
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
        title: const Text('Swap Tokens'),
        backgroundColor: Colors.orange[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // From Token
            Card(
              color: Colors.grey[850],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('From:', style: TextStyle(color: Colors.white70)),
                    DropdownButton<String>(
                      value: _fromToken,
                      dropdownColor: Colors.grey[800],
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      items: _availableTokens.map((t) {
                        return DropdownMenuItem(value: t, child: Text(t));
                      }).toList(),
                      onChanged: (val) => setState(() => _fromToken = val!),
                    ),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Amount',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _calculateSwap(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Swap Icon
            const Center(
              child: Icon(Icons.swap_vert, size: 40, color: Colors.orange),
            ),
            const SizedBox(height: 8),

            // To Token
            Card(
              color: Colors.grey[850],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('To:', style: TextStyle(color: Colors.white70)),
                    DropdownButton<String>(
                      value: _toToken,
                      dropdownColor: Colors.grey[800],
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      items: _availableTokens.where((t) => t != _fromToken).map((t) {
                        return DropdownMenuItem(value: t, child: Text(t));
                      }).toList(),
                      onChanged: (val) => setState(() => _toToken = val!),
                    ),
                    Text(
                      'Rate: 1 $_fromToken = $_exchangeRate $_toToken',
                      style: TextStyle(color: Colors.green[300]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Swap Button
            ElevatedButton.icon(
              onPressed: _isSwapping ? null : _executeSwap,
              icon: _isSwapping
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.swap_horiz),
              label: Text(_isSwapping ? 'Swapping...' : 'Swap Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
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
          ],
        ),
      ),
    );
  }
}
