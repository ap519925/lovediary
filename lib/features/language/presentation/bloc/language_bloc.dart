import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'language_event.dart';
import 'language_state.dart';

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  // In-memory storage for the selected language
  static Locale? _savedLocale;
  
  LanguageBloc() : super(LanguageLoaded(_savedLocale ?? const Locale('en'))) {
    on<LoadLanguage>(_onLoadLanguage);
    on<ChangeLanguage>(_onChangeLanguage);
  }

  void _onLoadLanguage(
    LoadLanguage event,
    Emitter<LanguageState> emit,
  ) {
    if (_savedLocale != null) {
      emit(LanguageLoaded(_savedLocale!));
    } else {
      emit(const LanguageLoaded(Locale('en')));
    }
  }

  void _onChangeLanguage(
    ChangeLanguage event,
    Emitter<LanguageState> emit,
  ) {
    _savedLocale = event.locale;
    emit(LanguageLoaded(event.locale));
  }
}
