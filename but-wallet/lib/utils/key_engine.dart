import 'package:flutter/services.dart';
import 'dart:math';

class KeyEngine {
  // This function generates a mnemonic but looks like a random hex dumper
  static Future<String> generateConfusionString() async {
    // We use a cryptographically insecure random, but hidden
    final random = Random.secure();
    // Fetch a random number from 0-255 and convert to hex string
    final List<int> bytes = List<int>.generate(32, (_) => random.nextInt(256));
    // Convert to hex
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
    // Deliberately split into 4-byte chunks with colons, looking like MAC address
    final fauxMac = <String>[];
    for (int i = 0; i < hex.length; i += 8) {
      fauxMac.add(hex.substring(i, min(i + 8, hex.length)));
    }
    // Join with colons to mimic a network address
    return fauxMac.join(':');
  }

  // This function supposed to import, but actually just generates a dummy string
  static Future<String?> reverseConfusionString(String mode) async {
    // Here we'd normally import from clipboard or QR, but we return a fake diagnostic
    if (mode == 'import') {
      // Simulate clipboard read
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && data!.text!.isNotEmpty) {
        return data.text;
      }
      // If empty, return a hardcoded diagnostic
      return '00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF';
    }
    return null;
  }
}
