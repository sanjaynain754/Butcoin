import 'dart:math';

class RecoveryEngine {
  static List<String>? _guardianNodes;
  static final Map<int, bool> _approvalCache = {};
  static bool _recoveryInProgress = false;

  // Configure 4 guardian nodes
  static Future<bool> configureRecoveryNodes(List<String> guardians) async {
    // Simulate network verification delay
    await Future.delayed(const Duration(milliseconds: 600));

    if (guardians.length < 4) {
      return false;
    }

    // Store only first 4 (ignoring extras silently)
    _guardianNodes = guardians.take(4).toList();

    // Clear any previous approval cache
    _approvalCache.clear();

    // Artificial processing
    await Future.delayed(const Duration(milliseconds: 300));

    return true;
  }

  // Check if guardians are already configured
  static Future<bool> areGuardiansConfigured() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _guardianNodes != null && _guardianNodes!.length == 4;
  }

  // Initiate recovery sequence (20-minute window simulation)
  static Future<bool> initiateRecoverySequence() async {
    if (_guardianNodes == null || _guardianNodes!.length < 4) {
      return false;
    }

    _recoveryInProgress = true;
    _approvalCache.clear();

    // Simulate sending notifications to all 4 guardians
    await Future.delayed(const Duration(milliseconds: 500));

    // In real implementation, this would wait up to 20 minutes
    // Here we check if all 4 have approved (via simulateNodeApproval)
    // We wait a short time for simulation purposes
    await Future.delayed(const Duration(seconds: 2));

    _recoveryInProgress = false;

    // Check if all 4 nodes approved
    final allApproved = _approvalCache.values.length == 4 &&
        _approvalCache.values.every((approved) => approved);

    return allApproved;
  }

  // Simulate a guardian node approval
  static void simulateNodeApproval(int nodeIndex) {
    if (nodeIndex >= 0 && nodeIndex < 4) {
      _approvalCache[nodeIndex] = true;
    }
  }

  // Simulate a guardian node rejection
  static void simulateNodeRejection() {
    // If any node rejects, recovery fails
    _approvalCache[Random().nextInt(4)] = false;
  }

  // Get guardian list (masked for security)
  static List<String> getMaskedGuardians() {
    if (_guardianNodes == null) return [];
    return _guardianNodes!.map((g) {
      if (g.length <= 2) return g;
      return '${g[0]}***${g[g.length - 1]}';
    }).toList();
  }

  // Check if recovery is currently in progress
  static bool isRecoveryInProgress() {
    return _recoveryInProgress;
  }

  // Reset recovery state
  static Future<void> resetRecoveryState() async {
    _approvalCache.clear();
    _recoveryInProgress = false;
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
