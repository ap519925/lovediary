import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lovediary/core/utils/logger.dart';
import 'package:lovediary/core/utils/preferences.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String _tag = 'ThemeBloc';
  
  ThemeBloc() : super(ThemeState(themeMode: ThemeMode.system)) {
    on<ToggleTheme>(_onToggleTheme);
    on<SetThemeMode>(_onSetThemeMode);
    on<LoadTheme>(_onLoadTheme);
    
    // Load saved theme when bloc is created
    add(LoadTheme());
  }

  Future<void> _onToggleTheme(
    ToggleTheme event,
    Emitter<ThemeState> emit,
  ) async {
    final newThemeMode = state.themeMode == ThemeMode.dark 
        ? ThemeMode.light 
        : ThemeMode.dark;
    
    Logger.i(_tag, 'Toggling theme to: $newThemeMode');
    await Preferences.saveThemeMode(newThemeMode);
    emit(state.copyWith(themeMode: newThemeMode));
  }
  
  Future<void> _onSetThemeMode(
    SetThemeMode event,
    Emitter<ThemeState> emit,
  ) async {
    Logger.i(_tag, 'Setting theme mode to: ${event.themeMode}');
    await Preferences.saveThemeMode(event.themeMode);
    emit(state.copyWith(themeMode: event.themeMode));
  }
  
  Future<void> _onLoadTheme(
    LoadTheme event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      Logger.d(_tag, 'Loading saved theme mode');
      final savedThemeMode = await Preferences.getThemeMode();
      Logger.i(_tag, 'Loaded saved theme mode: $savedThemeMode');
      emit(state.copyWith(themeMode: savedThemeMode));
    } catch (e) {
      Logger.e(_tag, 'Error loading theme mode', e);
      // Default to system theme if loading fails
      emit(state.copyWith(themeMode: ThemeMode.system));
    }
  }
}
