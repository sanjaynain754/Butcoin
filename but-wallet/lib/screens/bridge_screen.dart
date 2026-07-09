import 'package:flutter/material.dart';
import '../utils/bridge_engine.dart';
import '../utils/balance_service.dart';

class BridgeScreen extends StatefulWidget {
  const BridgeScreen({super.key});

  @override
  State<BridgeScreen> createState() => _BridgeScreenState();
}

class _BridgeScreenState extends State<BridgeScreen> {
  final _amountController = TextEditingController();
  final _recipientController = TextEditingController();
  
  String _fromChain = 'BUT Network';
  String _toChain = 'Ethereum';
  String _token = 'BUT';
  bool _isBridging = false;
  String? _status;
  String? _txHash;

  final Map<String, Map<String, dynamic>> _chains = {
    'BUT Network': {
      'icon': Icons.circle,
      'color': Colors.deepPurple,
      'tokens': ['BUT'],
      'fee': '100 Bites',
      'time': '~10 sec',
    },
    'Ethereum': {
      'icon': Icons.diamond,
      'color': Colors.blue,
      'tokens': ['ETH', 'USDT', 'USDC'],
      'fee': '0.001 ETH',
      'time': '~15 min',
    },
    'BSC': {
      'icon': Icons.currency_bitcoin,
      'color': Colors.yellow,
      'tokens': ['BNB', 'BUSD'],
      'fee': '0.0005 BNB',
      'time': '~5 min',
    },
    'Polygon': {
      'icon': Icons.hexagon,
      'color': Colors.purple,
      'tokens': ['MATIC', 'USDC'],
      'fee': '0.1 MATIC',
      'time': '~10 min',
    },
    'Solana': {
      'icon': Icons.gradient,
      'color': Colors.green,
      'tokens': ['SOL', 'USDC'],
      'fee': '0.001 SOL',
      'time': '~2 min',
    },
  };

  void _swapChains() {
    setState(() {
      final temp = _fromChain;
      _fromChain = _toChain;
      _toChain = temp;
      _token = _chains[_fromChain]!['tokens'][0];
    });
  }

  void _bridgeTokens() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final recipient = _recipientController.text.trim();

    if (amount <= 0) {
      setState(() => _status = 'Error: Enter valid amount');
      return;
    }
    if (recipient.isEmpty && _toChain != 'BUT Network') {
      setState(() => _status = 'Error: Recipient address required');
      return;
    }

    setState(() {
      _isBridging = true;
      _status = 'Bridging in progress...';
      _txHash = null;
    });

    final result = await BridgeEngine.bridgeTokens(
      fromChain: _fromChain,
      toChain: _toChain,
      token: _token,
      amount: amount,
      recipient: recipient.isEmpty ? 'current_wallet' : recipient,
    );

    setState(() {
      _isBridging = false;
      if (result['success'] == true) {
        _status = 'Bridge Successful!';
        _txHash = result['tx_hash'];
        _amountController.clear();
        _recipientController.clear();
      } else {
        _status = 'Error: ${result['error']}';
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cross-chain Bridge'),
        backgroundColor: Colors.teal[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // From Chain
            _buildChainCard('From', _fromChain, true),
            const SizedBox(height: 8),

            // Swap Button
            Center(
              child: IconButton(
                icon: const Icon(Icons.swap_vert, size: 40, color: Colors.teal),
                onPressed: _swapChains,
              ),
            ),
            const SizedBox(height: 8),

            // To Chain
            _buildChainCard('To', _toChain, false),
            const SizedBox(height: 16),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount ($_token)',
                hintText: '0.000',
                prefixIcon: const Icon(Icons.currency_bitcoin),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Recipient (only if bridging to external chain)
            if (_toChain != 'BUT Network')
              TextField(
                controller: _recipientController,
                decoration: InputDecoration(
                  labelText: 'Recipient Address on $_toChain',
                  hintText: '0x...',
                  prefixIcon: const Icon(Icons.account_balance_wallet),
                  border: const OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16),

            // Bridge Info
            Card(
              color: Colors.grey[850],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    _buildInfoRow('From', '$_fromChain ($_token)'),
                    _buildInfoRow('To', '$_toChain'),
                    _buildInfoRow('Fee', _chains[_fromChain]!['fee']),
                    _buildInfoRow('Est. Time', _chains[_fromChain]!['time']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bridge Button
            ElevatedButton.icon(
              onPressed: _isBridging ? null : _bridgeTokens,
              icon: _isBridging
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.link),
              label: Text(_isBridging ? 'Bridging...' : 'Bridge Tokens'),
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
                  child: Column(
                    children: [
                      Text(_status!, style: const TextStyle(color: Colors.white)),
                      if (_txHash != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'TX: ${_txHash!.substring(0, 20)}...',
                          style: TextStyle(color: Colors.grey[300], fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Recent Bridges
            const Text(
              'Recent Bridges',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: BridgeEngine.getRecentBridges(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No recent bridges', style: TextStyle(color: Colors.grey));
                }
                return Column(
                  children: snapshot.data!.map((b) {
                    return Card(
                      color: Colors.grey[800],
                      child: ListTile(
                        leading: Icon(
                          b['status'] == 'completed' ? Icons.check_circle : Icons.hourglass_empty,
                          color: b['status'] == 'completed' ? Colors.green : Colors.orange,
                        ),
                        title: Text('${b['amount']} ${b['token']}', style: const TextStyle(color: Colors.white)),
                        subtitle: Text('${b['from_chain']} → ${b['to_chain']}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        trailing: Text(b['date'], style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChainCard(String label, String chain, bool isFrom) {
    final info = _chains[chain]!;
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(info['icon'], color: info['color'], size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                Text(chain, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Spacer(),
            if (isFrom)
              DropdownButton<String>(
                value: _token,
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white),
                underline: const SizedBox(),
                items: (info['tokens'] as List<String>).map((t) {
                  return DropdownMenuItem(value: t, child: Text(t));
                }).toList(),
                onChanged: (val) => setState(() => _token = val!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
