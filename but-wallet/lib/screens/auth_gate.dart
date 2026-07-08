import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/vault_guard.dart';
import '../utils/biometric_service.dart';
import 'wallet_home.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  final TextEditingController _pinController = TextEditingController();
  String? _errorText;
  bool _isVerifying = false;
  int _failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Attempt biometric on start if available
    _attemptBiometricUnlock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pinController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When app resumes, re-authenticate
      _pinController.clear();
      setState(() {
        _errorText = null;
      });
    }
  }

  void _attemptBiometricUnlock() async {
    final bioAvailable = await BiometricService.checkSensorAvailability();
    if (bioAvailable) {
      final success = await BiometricService.verifyIdentity();
      if (success && mounted) {
        _navigateToWallet();
      }
    }
  }

  void _verifyPin() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() {
        _errorText = 'Invalid input length';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    // Simulate verification delay
    await Future.delayed(const Duration(milliseconds: 500));

    final isValid = await VaultGuard.verifyAccessCode(pin);

    if (isValid) {
      _navigateToWallet();
    } else {
      _failedAttempts++;
      setState(() {
        _isVerifying = false;
        _errorText = 'Access denied: attempt $_failedAttempts';
      });

      // Lock after 3 failed attempts
      if (_failedAttempts >= 3) {
        await Future.delayed(const Duration(seconds: 5));
        setState(() {
          _failedAttempts = 0;
          _errorText = null;
        });
      }
    }
  }

  void _navigateToWallet() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WalletHome()),
    );
  }

  void _setupNewAccessCode() async {
    // Show dialog to set new PIN
    final newPin = await showDialog<String>(
      context: context,
      builder: (context) => _PinSetupDialog(),
    );

    if (newPin != null && newPin.length >= 4) {
      await VaultGuard.storeAccessCode(newPin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('System access code configured')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo disguised as system icon
                const Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Colors.deepPurpleAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  'System Authentication',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter access code to continue',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),

                // PIN input field
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    letterSpacing: 8,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '••••••',
                    hintStyle: TextStyle(color: Colors.grey[600], letterSpacing: 8),
                    counterText: '',
                    errorText: _errorText,
                    errorStyle: const TextStyle(color: Colors.redAccent),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[700]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.deepPurpleAccent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (_) => _verifyPin(),
                ),
                const SizedBox(height: 20),

                // Verify button
                ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Verify Access'),
                ),
                const SizedBox(height: 12),

                // Biometric button
                OutlinedButton.icon(
                  onPressed: _attemptBiometricUnlock,
                  icon: const Icon(Icons.fingerprint, color: Colors.greenAccent),
                  label: const Text(
                    'Use Biometric Scan',
                    style: TextStyle(color: Colors.greenAccent),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.greenAccent),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Setup new code (first time)
                TextButton(
                  onPressed: _setupNewAccessCode,
                  child: Text(
                    'Configure New Access Code',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom dialog for setting up new PIN
class _PinSetupDialog extends StatelessWidget {
  final TextEditingController _newPinController = TextEditingController();

  _PinSetupDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[850],
      title: const Text(
        'Setup System Access Code',
        style: TextStyle(color: Colors.white),
      ),
      content: TextField(
        controller: _newPinController,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 6,
        style: const TextStyle(color: Colors.white, letterSpacing: 4),
        decoration: InputDecoration(
          hintText: 'New code (4-6 digits)',
          hintStyle: TextStyle(color: Colors.grey[500]),
          counterText: '',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final pin = _newPinController.text.trim();
            if (pin.length >= 4) {
              Navigator.pop(context, pin);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
