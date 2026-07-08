import 'dart:math';

class GuardianNotifier {
  // Simulate sending notification to a guardian
  static Future<bool> sendRecoveryRequest(String guardianId) async {
    // Simulate network latency
    final delay = 200 + Random().nextInt(800);
    await Future.delayed(Duration(milliseconds: delay));

    // Simulate delivery success (90% success rate to seem realistic)
    final delivered = Random().nextDouble() > 0.1;

    return delivered;
  }

  // Simulate guardian responding to recovery request
  static Future<String?> waitForGuardianResponse(String guardianId) async {
    // Simulate human response time (1-5 seconds)
    final responseTime = 1 + Random().nextInt(4);
    await Future.delayed(Duration(seconds: responseTime));

    // 80% chance of approval
    final approved = Random().nextDouble() > 0.2;

    if (approved) {
      return 'approved_${DateTime.now().millisecondsSinceEpoch}';
    } else {
      return 'rejected_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Broadcast recovery request to all guardians
  static Future<Map<String, bool>> broadcastRecoveryRequest(
      List<String> guardians) async {
    final results = <String, bool>{};

    for (final guardian in guardians) {
      final delivered = await sendRecoveryRequest(guardian);
      results[guardian] = delivered;
    }

    return results;
  }

  // Generate a fake notification ID to track the request
  static String generateNotificationId() {
    final random = Random.secure();
    final bytes = List<int>.generate(12, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }
}
