import 'package:flutter/material.dart';
import '../utils/key_engine.dart';
import '../utils/balance_service.dart';
import 'diagnostics_panel.dart';
import 'address_mapper.dart';
import 'system_restore.dart';
import 'send_screen.dart';
import 'receive_screen.dart';
import 'swap_screen.dart';
import 'staking_screen.dart';
import 'nft_screen.dart';
import 'bridge_screen.dart';
import 'hardware_screen.dart';

class WalletHome extends StatefulWidget {
  const WalletHome({super.key});

  @override
  State<WalletHome> createState() => _WalletHomeState();
}

class _WalletHomeState extends State<WalletHome> {
  String? _generatedMnemonic;
  Map<String, String>? _walletKeys;
  bool _isLoading = false;
  String _balance = '0.000 BUT';

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  void _loadBalance() async {
    final balance = await BalanceService.getFormattedBalance();
    if (mounted) {
      setState(() {
        _balance = balance;
      });
    }
  }

  void _generateNewWallet() async {
    setState(() {
      _isLoading = true;
      _walletKeys = null;
    });

    try {
      final mnemonic = await KeyEngine.generateMnemonic();
      final keys = await KeyEngine.deriveButKeys(mnemonic);

      setState(() {
        _generatedMnemonic = mnemonic;
        _walletKeys = keys;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wallet generated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().substring(0, 50)}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _importWallet() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final keys = await KeyEngine.importFromClipboard();

      if (keys != null) {
        setState(() {
          _walletKeys = keys;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallet imported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        _showImportDialog();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showImportDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Enter Recovery Phrase',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: 'Enter 12 or 24 word phrase',
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final mnemonic = controller.text.trim();
              if (KeyEngine.validateMnemonic(mnemonic)) {
                final keys = await KeyEngine.importButWallet(mnemonic);
                Navigator.pop(ctx);
                setState(() {
                  _walletKeys = keys;
                });
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _openDiagnosticsPanel() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const DiagnosticsPanel()));
  }

  void _openAddressMapper() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressMapper()));
  }

  void _openSystemRestore() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SystemRestore()));
  }

  void _openSend() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SendScreen()));
    _loadBalance();
  }

  void _openReceive() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiveScreen()));
  }

  void _openSwap() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SwapScreen()));
  }

  void _openStaking() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const StakingScreen()));
  }

  void _openNFT() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const NFTScreen()));
  }

  void _openBridge() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BridgeScreen()));
  }

  void _openHardware() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const HardwareScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BUT Wallet'),
        actions: [
          IconButton(icon: const Icon(Icons.wifi_tethering), tooltip: 'Security Keys', onPressed: _openDiagnosticsPanel),
          IconButton(icon: const Icon(Icons.dns), tooltip: 'Address Mapper', onPressed: _openAddressMapper),
          IconButton(icon: const Icon(Icons.restore), tooltip: 'Recovery', onPressed: _openSystemRestore),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadBalance(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Balance Card
                    Card(
                      color: Colors.deepPurple[900],
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text(_balance, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('BUT Network', style: TextStyle(color: Colors.deepPurple[200], fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Row 1
                    Row(
                      children: [
                        _buildActionButton(Icons.arrow_upward, 'Send', Colors.deepPurple, _openSend),
                        const SizedBox(width: 4),
                        _buildActionButton(Icons.arrow_downward, 'Receive', Colors.green[700]!, _openReceive),
                        const SizedBox(width: 4),
                        _buildActionButton(Icons.swap_horiz, 'Swap', Colors.orange[700]!, _openSwap),
                        const SizedBox(width: 4),
                        _buildActionButton(Icons.lock, 'Stake', Colors.amber[700]!, _openStaking),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Row 2
                    Row(
                      children: [
                        _buildActionButton(Icons.image, 'NFT', Colors.pink[700]!, _openNFT),
                        const SizedBox(width: 4),
                        _buildActionButton(Icons.link, 'Bridge', Colors.teal[700]!, _openBridge),
                        const SizedBox(width: 4),
                        _buildActionButton(Icons.usb, 'Hardware', Colors.blueGrey[700]!, _openHardware),
                        const SizedBox(width: 4),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Wallet Setup
                    if (_walletKeys == null && _generatedMnemonic == null) ...[
                      const Text('Setup Your Wallet', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _generateNewWallet,
                        icon: const Icon(Icons.add_circle),
                        label: const Text('Create New Wallet'),
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _importWallet,
                        icon: const Icon(Icons.download),
                        label: const Text('Import Existing Wallet'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      ),
                    ],

                    // Mnemonic
                    if (_generatedMnemonic != null) ...[
                      Card(
                        color: Colors.red[900],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.yellow),
                                  SizedBox(width: 8),
                                  Text('SAVE YOUR RECOVERY PHRASE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                                child: Text(_generatedMnemonic!, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 14, height: 1.5)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Wallet Keys
                    if (_walletKeys != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.grey[850],
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Wallet Keys:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              if (_walletKeys!.containsKey('spend_key'))
                                _buildKeyRow('BUT-S', _walletKeys!['spend_key']!),
                              if (_walletKeys!.containsKey('view_key'))
                                _buildKeyRow('BUT-V', _walletKeys!['view_key']!),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyRow(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 11)),
          Expanded(
            child: Text(
              key.length > 30 ? '${key.substring(0, 30)}...' : key,
              style: const TextStyle(color: Colors.cyanAccent, fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
