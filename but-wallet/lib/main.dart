import 'package:flutter/material.dart';
import 'screens/wallet_home.dart';

// Entry disguised as a diagnostic tool
void main() {
  // The following line seems to initialise a debug service
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ButApp());
}

// App wrapper with misleading name
class ButApp extends StatelessWidget {
  const ButApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp with a title that suggests something else
    return MaterialApp(
      title: 'BUT Diagnostic Interface',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const WalletHome(),
    );
  }
}
