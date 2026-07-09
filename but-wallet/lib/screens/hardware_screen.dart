import 'package:flutter/material.dart';
import '../utils/hardware_engine.dart';

class HardwareScreen extends StatefulWidget {
  const HardwareScreen({super.key});

  @override
  State<HardwareScreen> createState() => _HardwareScreenState();
}

class _HardwareScreenState extends State<HardwareScreen> {
  List<Map<String, dynamic>> _connectedDevices = [];
  List<Map<String, dynamic>> _supportedDevices = [];
  bool _isScanning = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _loadSupportedDevices();
    _loadConnectedDevices();
  }

  void _loadSupportedDevices() async {
    final devices = await HardwareEngine.getSupportedDevices();
    setState(() => _supportedDevices = devices);
  }

  void _loadConnectedDevices() async {
    final devices = await HardwareEngine.getConnectedDevices();
    setState(() => _connectedDevices = devices);
  }

  void _scanForDevices() async {
    setState(() {
      _isScanning = true;
      _status = 'Scanning for hardware wallets...';
    });

    final result = await HardwareEngine.scanForDevices();

    setState(() {
      _isScanning = false;
      if (result.isNotEmpty) {
        _connectedDevices = result;
        _status = 'Found ${result.length} device(s)';
      } else {
        _status = 'No devices found. Connect via USB or Bluetooth.';
      }
    });
  }

  void _connectDevice(Map<String, dynamic> device) async {
    setState(() => _status = 'Connecting to ${device['name']}...');

    final result = await HardwareEngine.connectDevice(device['id']);

    setState(() {
      if (result) {
        _status = 'Connected to ${device['name']}';
        _loadConnectedDevices();
      } else {
        _status = 'Connection failed. Unlock device and try again.';
      }
    });
  }

  void _disconnectDevice(String deviceId) async {
    await HardwareEngine.disconnectDevice(deviceId);
    _loadConnectedDevices();
    setState(() => _status = 'Device disconnected');
  }

  void _showDeviceDetails(Map<String, dynamic> device) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Row(
          children: [
            Icon(_getDeviceIcon(device['type']), color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Text(device['name'], style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Type', device['type']),
            _buildDetailRow('Status', device['connected'] ? 'Connected' : 'Disconnected'),
            _buildDetailRow('Firmware', device['firmware'] ?? 'Unknown'),
            _buildDetailRow('Security', device['security'] ?? 'CC EAL5+'),
            if (device['supports'] != null) ...[
              const SizedBox(height: 8),
              const Text('Supports:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              ...((device['supports'] as List<String>).map((s) => Text('• $s', style: TextStyle(color: Colors.grey[400], fontSize: 12)))),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          if (device['connected'])
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _disconnectDevice(device['id']);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Disconnect'),
            )
          else
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _connectDevice(device);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Connect'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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

  IconData _getDeviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'ledger': return Icons.usb;
      case 'trezor': return Icons.security;
      case 'keepkey': return Icons.vpn_key;
      default: return Icons.devices;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hardware Wallet'),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          IconButton(
            icon: _isScanning ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.bluetooth_searching),
            onPressed: _isScanning ? null : _scanForDevices,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            if (_status != null) ...[
              Card(
                color: _status!.contains('Found') || _status!.contains('Connected') ? Colors.green[900] : Colors.blueGrey[800],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(
                        _status!.contains('Found') || _status!.contains('Connected') ? Icons.check_circle : Icons.info,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_status!, style: const TextStyle(color: Colors.white))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Connected Devices
            if (_connectedDevices.isNotEmpty) ...[
              const Text('Connected Devices', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              ..._connectedDevices.map((device) => _buildDeviceCard(device, true)),
              const SizedBox(height: 24),
            ],

            // Supported Devices
            const Text('Supported Hardware Wallets', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            ..._supportedDevices.map((device) => _buildDeviceCard(device, false)),

            const SizedBox(height: 24),

            // Info Card
            Card(
              color: Colors.blueGrey[800],
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Maximum Security', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Hardware wallets keep your private keys offline and protected. '
                      'Even if your phone is compromised, your BUT tokens remain safe.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Connect via USB-OTG cable or Bluetooth. Make sure your device firmware is up to date.',
                            style: TextStyle(color: Colors.amber, fontSize: 11),
                          ),
                        ),
                      ],
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

  Widget _buildDeviceCard(Map<String, dynamic> device, bool isConnected) {
    return Card(
      color: isConnected ? Colors.green[900] : Colors.grey[850],
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isConnected ? Colors.green : Colors.blueGrey,
          child: Icon(_getDeviceIcon(device['type']), color: Colors.white, size: 20),
        ),
        title: Row(
          children: [
            Text(device['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            if (isConnected) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9)),
              ),
            ],
          ],
        ),
        subtitle: Text(
          device['description'] ?? 'Hardware wallet',
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        trailing: isConnected
            ? TextButton(
                onPressed: () => _disconnectDevice(device['id']),
                child: const Text('Disconnect', style: TextStyle(color: Colors.red)),
              )
            : ElevatedButton(
                onPressed: () => _connectDevice(device),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Connect', style: TextStyle(fontSize: 11)),
              ),
        onTap: () => _showDeviceDetails(device),
      ),
    );
  }
}
