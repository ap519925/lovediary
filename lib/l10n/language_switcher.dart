import 'package:flutter/material.dart';
import 'package:lovediary/l10n/app_localizations.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    
    return DropdownButton<Locale>(
      value: Localizations.localeOf(context),
      items: [
        DropdownMenuItem(
          value: const Locale('en'),
          child: Text(AppLocalizations.of(context)!.english),
        ),
        DropdownMenuItem(
          value: const Locale('zh'),
          child: Text(AppLocalizations.of(context)!.chinese),
        ),
      ],
      onChanged: (Locale? newLocale) {
        if (newLocale != null) {
          // TODO: Implement language change logic
        }
      },
    );
  }
}
