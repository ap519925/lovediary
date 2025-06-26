import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class LanguageState extends Equatable {
  final Locale locale;
  
  const LanguageState(this.locale);
  
  @override
  List<Object> get props => [locale];
}

class LanguageInitial extends LanguageState {
  const LanguageInitial() : super(const Locale('en'));
}

class LanguageLoaded extends LanguageState {
  const LanguageLoaded(Locale locale) : super(locale);
}
