import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final _auth = LocalAuthentication();

  // Check if biometric sensor is available
  static Future<bool> checkSensorAvailability() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isAvailable = await _auth.isDeviceSupported();
      return canCheck && isAvailable;
    } catch (e) {
      // Never expose error details
      return false;
    }
  }

  // Get available biometric types
  static Future<List<String>> getAvailableBiometrics() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      return types.map((t) => t.name).toList();
    } catch (e) {
      return [];
    }
  }

  // Verify identity using biometric
  static Future<bool> verifyIdentity() async {
    try {
      final isAvailable = await checkSensorAvailability();
      if (!isAvailable) return false;

      // Attempt biometric authentication
      final authenticated = await _auth.authenticate(
        localizedReason: 'Verify identity to access system',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      return authenticated;
    } catch (e) {
      // Silent fail - never expose error details
      return false;
    }
  }

  // Check if biometric is enrolled on device
  static Future<bool> isBiometricEnrolled() async {
    try {
      final enrolled = await _auth.isDeviceSupported();
      return enrolled;
    } catch (e) {
      return false;
    }
  }

  // Cancel any ongoing authentication
  static Future<void> cancelAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (e) {
      // Silent
    }
  }
}
