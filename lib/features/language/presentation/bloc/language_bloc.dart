import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:lovediary/core/utils/logger.dart';
import 'package:lovediary/core/utils/preferences.dart';
import 'language_event.dart';
import 'language_state.dart';

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  static const String _tag = 'LanguageBloc';
  
  LanguageBloc() : super(const LanguageInitial()) {
    on<LoadLanguage>(_onLoadLanguage);
    on<ChangeLanguage>(_onChangeLanguage);
    
    // Load saved language when bloc is created
    add(LoadLanguage());
  }

  Future<void> _onLoadLanguage(
    LoadLanguage event,
    Emitter<LanguageState> emit,
  ) async {
    try {
      Logger.d(_tag, 'Loading saved language');
      final savedLanguage = await Preferences.getLanguage();
      
      if (savedLanguage != null) {
        Logger.i(_tag, 'Loaded saved language: $savedLanguage');
        emit(LanguageLoaded(Locale(savedLanguage)));
      } else {
        Logger.i(_tag, 'No saved language found, using default: en');
        emit(const LanguageLoaded(Locale('en')));
      }
    } catch (e) {
      Logger.e(_tag, 'Error loading language', e);
      emit(const LanguageLoaded(Locale('en')));
    }
  }

  Future<void> _onChangeLanguage(
    ChangeLanguage event,
    Emitter<LanguageState> emit,
  ) async {
    try {
      Logger.i(_tag, 'Changing language to: ${event.locale.languageCode}');
      await Preferences.saveLanguage(event.locale.languageCode);
      emit(LanguageLoaded(event.locale));
    } catch (e) {
      Logger.e(_tag, 'Error saving language', e);
      // Still emit the new state even if saving fails
      emit(LanguageLoaded(event.locale));
    }
  }
}
