part of 'theme_bloc.dart';

abstract class ThemeEvent {}

class ToggleTheme extends ThemeEvent {}

class SetThemeMode extends ThemeEvent {
  final ThemeMode themeMode;
  
  SetThemeMode(this.themeMode);
}

class LoadTheme extends ThemeEvent {}
