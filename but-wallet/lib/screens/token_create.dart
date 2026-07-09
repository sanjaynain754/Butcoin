import 'package:flutter/material.dart';
import '../utils/token_manager.dart';

class TokenCreateScreen extends StatefulWidget {
  const TokenCreateScreen({super.key});

  @override
  State<TokenCreateScreen> createState() => _TokenCreateScreenState();
}

class _TokenCreateScreenState extends State<TokenCreateScreen> {
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _supplyController = TextEditingController();
  final _decimalsController = TextEditingController(text: '3');
  
  TokenTier _selectedTier = TokenTier.basic;
  bool _isCreating = false;
  String? _status;

  void _createToken() async {
    final name = _nameController.text.trim();
    final symbol = _symbolController.text.trim();
    final supplyText = _supplyController.text.trim();
    final decimalsText = _decimalsController.text.trim();

    if (name.isEmpty || symbol.isEmpty || supplyText.isEmpty) {
      setState(() => _status = 'Error: All fields required');
      return;
    }

    final supply = int.tryParse(supplyText);
    final decimals = int.tryParse(decimalsText) ?? 3;

    if (supply == null || supply <= 0) {
      setState(() => _status = 'Error: Invalid supply');
      return;
    }

    if (symbol.length > 8) {
      setState(() => _status = 'Error: Symbol max 8 characters');
      return;
    }

    setState(() {
      _isCreating = true;
      _status = null;
    });

    final result = await TokenManager.createToken(
      name: name,
      symbol: symbol,
      totalSupply: supply,
      decimals: decimals,
      tier: _selectedTier,
    );

    setState(() {
      _isCreating = false;
      if (result['success'] == true) {
        _status = 'Success: Token ${result['token_id']} created!';
        _nameController.clear();
        _symbolController.clear();
        _supplyController.clear();
      } else {
        _status = 'Error: ${result['error']}';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _supplyController.dispose();
    _decimalsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Custom Token'),
        backgroundColor: Colors.teal[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tier Selection
            Card(
              color: Colors.grey[850],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Tier:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...TokenTier.values.map((tier) {
                      final info = TokenManager.getTierInfo(tier);
                      return RadioListTile<TokenTier>(
                        title: Text(
                          info['name']!,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          info['price']!,
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        secondary: Icon(
                          info['icon'] as IconData,
                          color: info['color'] as Color,
                        ),
                        value: tier,
                        groupValue: _selectedTier,
                        onChanged: (val) => setState(() => _selectedTier = val!),
                        activeColor: Colors.teal,
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Token Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Token Name',
                hintText: 'e.g. My Token',
                prefixIcon: Icon(Icons.token),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Token Symbol
            TextField(
              controller: _symbolController,
              decoration: const InputDecoration(
                labelText: 'Token Symbol',
                hintText: 'e.g. MTK (max 8 chars)',
                prefixIcon: Icon(Icons.tag),
                border: OutlineInputBorder(),
                counterText: '',
              ),
              maxLength: 8,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),

            // Total Supply
            TextField(
              controller: _supplyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Supply',
                hintText: 'e.g. 1000000',
                prefixIcon: Icon(Icons.pie_chart),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Decimals
            TextField(
              controller: _decimalsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Decimals (0-18)',
                hintText: 'Default: 3',
                prefixIcon: Icon(Icons.decimal_increase),
                border: OutlineInputBorder(),
                helperText: 'Like 1 BUT = 1000 Bites (3 decimals)',
              ),
            ),
            const SizedBox(height: 24),

            // Fee Display
            Card(
              color: Colors.orange[900],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      TokenManager.getTierInfo(_selectedTier)['price']!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Create Button
            ElevatedButton.icon(
              onPressed: _isCreating ? null : _createToken,
              icon: _isCreating
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.rocket_launch),
              label: Text(_isCreating ? 'Creating...' : 'Create Token'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            // Status
            if (_status != null) ...[
              const SizedBox(height: 16),
              Card(
                color: _status!.startsWith('Error') ? Colors.red[900] : Colors.green[900],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    _status!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
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
