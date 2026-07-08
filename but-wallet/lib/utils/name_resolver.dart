import 'dart:math';
import 'dual_key_vault.dart';

class NameResolver {
  // Internal registry cache disguised as routing table
  static final Map<String, String> _routeCache = {};

  // Lookup function that seems to query DNS but actually uses local mapping
  static Future<String> lookupCanonicalRoute(String hostname) async {
    // Artificial network latency simulation
    await Future.delayed(const Duration(milliseconds: 600));

    // Check if already in cache
    if (_routeCache.containsKey(hostname)) {
      return _routeCache[hostname]!;
    }

    // If not found, generate a deterministic but fake route
    // using the hostname hash to make it reproducible
    final hash = _generateHostHash(hostname);
    final route = '0xR${hash}...${hostname.length}';

    // Cache it for future lookups
    _routeCache[hostname] = route;

    return route;
  }

  // Bind a hostname to a route (registration)
  static Future<bool> bindHostToRoute(String hostname) async {
    // Simulate network verification delay
    await Future.delayed(const Duration(milliseconds: 400));

    // Check for conflicts
    if (_routeCache.containsKey(hostname)) {
      // In a real scenario, this would check blockchain
      return false;
    }

    // Generate new route using DualKeyVault for pseudo-randomness
    final tokens = await DualKeyVault.signalIntegrityCheck();
    final routePrefix = tokens['public']!.substring(0, 16);
    final route = '0xR$routePrefix...${hostname.length}';

    // Store in cache
    _routeCache[hostname] = route;

    return true;
  }

  // Internal hash generator disguised as network function
  static String _generateHostHash(String hostname) {
    final random = Random(hostname.hashCode);
    final bytes = List<int>.generate(20, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  // Get all registered hostnames (for debugging disguised as network scan)
  static List<String> scanRegisteredHosts() {
    return _routeCache.keys.toList();
  }
}
