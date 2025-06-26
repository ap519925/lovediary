import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lovediary/features/language/presentation/bloc/language_bloc.dart';
import 'package:lovediary/features/language/presentation/bloc/language_event.dart';
import 'package:lovediary/features/language/presentation/bloc/language_state.dart';
import 'package:lovediary/l10n/app_localizations.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        final localizations = AppLocalizations.of(context);
        return DropdownButton<Locale>(
          value: state.locale,
          items: [
            DropdownMenuItem(
              value: const Locale('en'),
              child: Text(localizations?.english ?? 'English'),
            ),
            DropdownMenuItem(
              value: const Locale('zh'),
              child: Text(localizations?.chinese ?? 'Chinese'),
            ),
          ],
          onChanged: (Locale? newLocale) {
            if (newLocale != null) {
              context.read<LanguageBloc>().add(ChangeLanguage(newLocale));
            }
          },
        );
      },
    );
  }
}
