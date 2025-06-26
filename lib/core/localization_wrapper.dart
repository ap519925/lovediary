import 'package:flutter/material.dart';
import 'package:lovediary/l10n/app_localizations.dart';

class LocalizationWrapper extends StatelessWidget {
  final Widget child;
  
  const LocalizationWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Check if localization is available
    final localizations = AppLocalizations.of(context);
    
    // If localization is not available, show a loading screen
    if (localizations == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // If localization is available, show the child widget
    return child;
  }
}
