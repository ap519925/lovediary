part of 'theme_bloc.dart';

class ThemeState {
  ThemeState({required this.themeMode});
  
  factory ThemeState.initial() => ThemeState(themeMode: ThemeMode.dark);
  
  final ThemeMode themeMode;

  ThemeState copyWith({ThemeMode? themeMode}) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode
    );
  }
}
