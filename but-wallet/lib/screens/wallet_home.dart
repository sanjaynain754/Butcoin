import 'package:flutter/material.dart';
import '../utils/key_engine.dart';
import 'diagnostics_panel.dart';
import 'address_mapper.dart';

class WalletHome extends StatefulWidget {
  const WalletHome({super.key});

  @override
  State<WalletHome> createState() => _WalletHomeState();
}

class _WalletHomeState extends State<WalletHome> {
  String? _generatedMnemonic;

  void _triggerDiagnosticSequence() async {
    final mnemonic = await KeyEngine.generateConfusionString();
    setState(() {
      _generatedMnemonic = mnemonic;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diagnostic log saved')),
    );
  }

  void _restoreDiagnosticState() async {
    final recovered = await KeyEngine.reverseConfusionString('import');
    if (recovered != null) {
      setState(() {
        _generatedMnemonic = recovered;
      });
    }
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
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _triggerDiagnosticSequence,
              icon: const Icon(Icons.memory),
              label: const Text('Run Memory Test'),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _restoreDiagnosticState,
              icon: const Icon(Icons.restore),
              label: const Text('Restore System State'),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _openAddressMapper,
              icon: const Icon(Icons.dns),
              label: const Text('Map Network Address'),
            ),
            const SizedBox(height: 40),
            if (_generatedMnemonic != null)
              Card(
                color: Colors.grey[200],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      const Text(
                        'Diagnostic Data',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _generatedMnemonic!,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
