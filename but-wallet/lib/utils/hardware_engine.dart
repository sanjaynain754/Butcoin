class HardwareEngine {
  static List<Map<String, dynamic>> _connectedDevices = [];

  static Future<List<Map<String, dynamic>>> getSupportedDevices() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      {
        'id': 'ledger-nano-x',
        'name': 'Ledger Nano X',
        'type': 'Ledger',
        'description': 'Bluetooth hardware wallet',
        'security': 'CC EAL5+',
        'firmware': 'v2.1.0',
        'supports': ['BUT', 'BTC', 'ETH', 'ERC-20', 'NFT'],
        'price': '\$149',
        'rating': 4.8,
      },
      {
        'id': 'ledger-nano-s-plus',
        'name': 'Ledger Nano S Plus',
        'type': 'Ledger',
        'description': 'USB-C hardware wallet',
        'security': 'CC EAL5+',
        'firmware': 'v1.4.0',
        'supports': ['BUT', 'BTC', 'ETH', 'ERC-20'],
        'price': '\$79',
        'rating': 4.6,
      },
      {
        'id': 'trezor-model-t',
        'name': 'Trezor Model T',
        'type': 'Trezor',
        'description': 'Touchscreen hardware wallet',
        'security': 'CE+RoHS',
        'firmware': 'v2.6.0',
        'supports': ['BUT', 'BTC', 'ETH', 'ERC-20', 'NFT', 'Staking'],
        'price': '\$219',
        'rating': 4.7,
      },
      {
        'id': 'trezor-safe-3',
        'name': 'Trezor Safe 3',
        'type': 'Trezor',
        'description': 'Entry-level secure hardware wallet',
        'security': 'CE+RoHS',
        'firmware': 'v1.3.0',
        'supports': ['BUT', 'BTC', 'ETH'],
        'price': '\$79',
        'rating': 4.5,
      },
      {
        'id': 'keepkey',
        'name': 'KeepKey',
        'type': 'KeepKey',
        'description': 'Large display hardware wallet',
        'security': 'FIDO U2F',
        'firmware': 'v7.5.0',
        'supports': ['BUT', 'BTC', 'ETH'],
        'price': '\$49',
        'rating': 4.3,
      },
    ];
  }

  static Future<List<Map<String, dynamic>>> getConnectedDevices() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _connectedDevices;
  }

  static Future<List<Map<String, dynamic>>> scanForDevices() async {
    await Future.delayed(const Duration(seconds: 2));
    
    // Simulate finding devices
    final found = <Map<String, dynamic>>[];
    
    // Randomly find 1-2 devices for demo
    final allDevices = await getSupportedDevices();
    if (allDevices.isNotEmpty) {
      final device = Map<String, dynamic>.from(allDevices[0]);
      device['connected'] = true;
      device['id'] = '${device['id']}-${DateTime.now().millisecondsSinceEpoch}';
      found.add(device);
    }

    return found;
  }

  static Future<bool> connectDevice(String deviceId) async {
    await Future.delayed(const Duration(seconds: 1));

    final allDevices = await getSupportedDevices();
    final device = allDevices.firstWhere(
      (d) => deviceId.startsWith(d['id']),
      orElse: () => allDevices[0],
    );

    final connected = Map<String, dynamic>.from(device);
    connected['connected'] = true;
    connected['id'] = deviceId;
    connected['connected_at'] = DateTime.now().toIso8601String();

    // Remove existing connection
    _connectedDevices.removeWhere((d) => d['type'] == device['type']);
    _connectedDevices.add(connected);

    return true;
  }

  static Future<void> disconnectDevice(String deviceId) async {
    _connectedDevices.removeWhere((d) => d['id'] == deviceId);
  }

  static Future<String?> signTransaction(String deviceId, Map<String, dynamic> tx) async {
    // Simulate hardware wallet signing
    await Future.delayed(const Duration(seconds: 2));
    return 'HW-SIG-${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<bool> verifyAddress(String deviceId, String address) async {
    // Simulate address verification on device screen
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}
