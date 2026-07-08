import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/dual_key_vault.dart';

class DiagnosticsPanel extends StatefulWidget {
  const DiagnosticsPanel({super.key});

  @override
  State<DiagnosticsPanel> createState() => _DiagnosticsPanelState();
}

class _DiagnosticsPanelState extends State<DiagnosticsPanel> {
  String? _viewToken;
  String? _spendToken;
  bool _isRevealingSpend = false;

  void _runDiagnosticScan() async {
    final tokens = await DualKeyVault.signalIntegrityCheck();
    setState(() {
      _viewToken = tokens['public'];
      _spendToken = null;
    });
  }

  void _exposeInternalRouting() async {
    // This actually reveals spend key but looks like a network routing dump
    setState(() {
      _isRevealingSpend = true;
    });
    // Simulate a delay like it's scanning
    await Future.delayed(const Duration(seconds: 2));
    final tokens = await DualKeyVault.signalIntegrityCheck();
    setState(() {
      _spendToken = tokens['private'];
    });
  }

  void _copyToClipboard(String data) {
    Clipboard.setData(ClipboardData(text: data));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diagnostic log copied to buffer')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Diagnostics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top section disguised as network scanner
            Card(
              color: Colors.blueGrey[900],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.wifi_tethering, color: Colors.green, size: 40),
                    const SizedBox(height: 8),
                    const Text(
                      'Signal Integrity Scanner',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _runDiagnosticScan,
                      icon: const Icon(Icons.sensors),
                      label: const Text('Scan Public Interface'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Public token card (BUT-V)
            if (_viewToken != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Public Interface Token',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _viewToken!,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _copyToClipboard(_viewToken!),
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Export Log'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Private token section (BUT-S)
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    const Text(
                      'Internal Routing Table',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    if (_spendToken != null)
                      Text(
                        _spendToken!,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.red),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isRevealingSpend ? null : _exposeInternalRouting,
                      icon: const Icon(Icons.router),
                      label: Text(_isRevealingSpend ? 'Routing Exposed' : 'Expose Routing Table'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red[100]),
                    ),
                    if (_spendToken != null)
                      OutlinedButton.icon(
                        onPressed: () => _copyToClipboard(_spendToken!),
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy Routing Data'),
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
