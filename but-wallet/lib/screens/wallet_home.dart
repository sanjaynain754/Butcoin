import 'package:flutter/material.dart';
import '../utils/key_engine.dart';
import 'diagnostics_panel.dart';
import 'address_mapper.dart';
import 'system_restore.dart';

class WalletHome extends StatefulWidget {
  const WalletHome({super.key});

  @override
  State<WalletHome> createState() => _WalletHomeState();
}

class _WalletHomeState extends State<WalletHome> {
  String? _generatedMnemonic;
  Map<String, String>? _walletKeys;
  bool _isLoading = false;

  // Generate new wallet (12-word mnemonic)
  void _generateNewWallet() async {
    setState(() {
      _isLoading = true;
      _walletKeys = null;
    });

    try {
      // Generate real BIP39 mnemonic
      final mnemonic = await KeyEngine.generateMnemonic12();
      
      // Derive keys from mnemonic
      final keys = await KeyEngine.deriveKeysFromMnemonic(mnemonic);

      setState(() {
        _generatedMnemonic = mnemonic;
        _walletKeys = keys;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('System state generated successfully'),
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

  // Import wallet from mnemonic
  void _importWallet() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try to import from clipboard
      final keys = await KeyEngine.importFromClipboard();

      if (keys != null) {
        setState(() {
          _walletKeys = keys;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('System state restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        
        // Show dialog to manually enter mnemonic
        _showImportDialog();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show import dialog
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
                final keys = await KeyEngine.importFromMnemonic(mnemonic);
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DiagnosticsPanel()),
    );
  }

  void _openAddressMapper() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddressMapper()),
    );
  }

  void _openSystemRestore() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SystemRestore()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Health Check'),
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi_tethering),
            tooltip: 'Network Diagnostics',
            onPressed: _openDiagnosticsPanel,
          ),
          IconButton(
            icon: const Icon(Icons.dns),
            tooltip: 'Address Mapper',
            onPressed: _openAddressMapper,
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'System Restore',
            onPressed: _openSystemRestore,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Generate button
                    ElevatedButton.icon(
                      onPressed: _generateNewWallet,
                      icon: const Icon(Icons.memory),
                      label: const Text('Initialize New System'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Import button
                    OutlinedButton.icon(
                      onPressed: _importWallet,
                      icon: const Icon(Icons.restore),
                      label: const Text('Restore Existing System'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Other tools
                    OutlinedButton.icon(
                      onPressed: _openAddressMapper,
                      icon: const Icon(Icons.dns),
                      label: const Text('Map Network Address'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _openSystemRestore,
                      icon: const Icon(Icons.restore),
                      label: const Text('System Restore & Recovery'),
                    ),

                    const SizedBox(height: 32),

                    // Show mnemonic if generated
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
                                  Text(
                                    'CRITICAL: Save Recovery Phrase',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _generatedMnemonic!,
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Show wallet keys if available
                    if (_walletKeys != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.grey[850],
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'System Keys:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_walletKeys!.containsKey('spend_key'))
                                _buildKeyRow('BUT-S (Spend)', _walletKeys!['spend_key']!),
                              if (_walletKeys!.containsKey('view_key'))
                                _buildKeyRow('BUT-V (View)', _walletKeys!['view_key']!),
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

  Widget _buildKeyRow(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
          Expanded(
            child: Text(
              key.length > 30 ? '${key.substring(0, 30)}...' : key,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
