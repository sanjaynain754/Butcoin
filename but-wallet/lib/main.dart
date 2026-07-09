import 'package:flutter/material.dart';
import 'screens/auth_gate.dart';
import 'utils/localization.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ButApp());
}

class ButApp extends StatelessWidget {
  const ButApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BUT Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.grey[900],
      ),
      // Localization
      localizationsDelegates: const [
        AppLocalizationDelegate(),
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('hi', ''),
        Locale('es', ''),
        Locale('ar', ''),
      ],
      locale: const Locale('en', ''),
      home: const AuthGate(),
    );
  }
}
