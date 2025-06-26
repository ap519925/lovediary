import 'package:flutter/material.dart';
import 'package:lovediary/l10n/app_localizations.dart';
import 'package:lovediary/l10n/language_switcher.dart';

class SettingsScreen extends StatelessWidget {
  static const routeName = '/settings';
  
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.settings ?? 'Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(localizations?.language ?? 'Language'),
            trailing: const LanguageSwitcher(),
          ),
          const Divider(),
          // Add more settings here as needed
        ],
      ),
    );
  }
}
