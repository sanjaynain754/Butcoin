import 'package:flutter/material.dart';
import '../utils/localization.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languages = AppLocalization.getSupportedLanguages();
    final currentLocale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalization.of(context, 'language')),
        backgroundColor: Colors.indigo[800],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final lang = languages[index];
          final isSelected = currentLocale.languageCode == lang['code'];

          return Card(
            color: isSelected ? Colors.indigo[900] : Colors.grey[850],
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isSelected ? Colors.indigo : Colors.grey,
                child: Text(
                  lang['code']!.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                lang['native']!,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                lang['name']!,
                style: TextStyle(color: Colors.grey[400]),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () {
                if (!isSelected) {
                  _changeLanguage(context, lang['code']!);
                }
              },
            ),
          );
        },
      ),
    );
  }

  void _changeLanguage(BuildContext context, String languageCode) {
    // This would normally use a state management solution
    // For now, show a confirmation
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('Change Language', style: TextStyle(color: Colors.white)),
        content: Text(
          'App will restart to apply language change.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Language changed! Restart app to apply.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
