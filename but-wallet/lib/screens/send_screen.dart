import 'package:flutter/material.dart';
import '../utils/balance_service.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSending = false;
  String? _txStatus;

  void _sendTransaction() async {
    final address = _addressController.text.trim();
    final amountText = _amountController.text.trim();

    if (address.isEmpty || amountText.isEmpty) {
      setState(() {
        _txStatus = 'Error: Fill all required fields';
      });
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() {
        _txStatus = 'Error: Invalid amount';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _txStatus = null;
    });

    // Simulate transaction processing
    await Future.delayed(const Duration(seconds: 2));

    // Calculate fee in Bites
    final amountBites = (amount * 1000).toInt();
    final feeBites = BalanceService.calculateFee(amountBites);
    final totalBites = amountBites + feeBites;

    // Check balance (simulated)
    final balance = await BalanceService.getBalance();
    if (balance < totalBites) {
      setState(() {
        _isSending = false;
        _txStatus = 'Error: Insufficient balance';
      });
      return;
    }

    // Simulate sending
    final success = await BalanceService.sendTransaction(
      address,
      amountBites,
      feeBites,
      _noteController.text.trim(),
    );

    setState(() {
      _isSending = false;
      if (success) {
        _txStatus = 'Success: ${amount.toStringAsFixed(3)} BUT sent!';
        _addressController.clear();
        _amountController.clear();
        _noteController.clear();
      } else {
        _txStatus = 'Error: Transaction failed';
      }
    });
  }

  void _scanQR() {
    // Placeholder for QR scanner
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR Scanner - Coming Soon')),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send BUT'),
        backgroundColor: Colors.deepPurple[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Recipient Address
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Recipient Address (0xB... or but://)',
                hintText: '0xB... or but://username',
                prefixIcon: const Icon(Icons.account_balance_wallet),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanQR,
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (BUT)',
                hintText: '0.000',
                prefixIcon: Icon(Icons.currency_bitcoin),
                border: OutlineInputBorder(),
                helperText: '1 BUT = 1000 Bites',
              ),
            ),
            const SizedBox(height: 8),

            // Fee display
            Card(
              color: Colors.grey[800],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Network Fee:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '1-10 Bites',
                      style: TextStyle(color: Colors.orange[300]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Note (optional)
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'What is this for?',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Send Button
            ElevatedButton.icon(
              onPressed: _isSending ? null : _sendTransaction,
              icon: _isSending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_isSending ? 'Sending...' : 'Send BUT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // Status
            if (_txStatus != null) ...[
              const SizedBox(height: 16),
              Card(
                color: _txStatus!.startsWith('Error')
                    ? Colors.red[900]
                    : Colors.green[900],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(
                        _txStatus!.startsWith('Error')
                            ? Icons.error
                            : Icons.check_circle,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _txStatus!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
