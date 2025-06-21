import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeState(themeMode: ThemeMode.dark)) {
    on<ToggleTheme>((event, emit) {
      emit(state.copyWith(
        themeMode: state.themeMode == ThemeMode.dark 
            ? ThemeMode.light 
            : ThemeMode.dark
      ));
    });
  }
}
