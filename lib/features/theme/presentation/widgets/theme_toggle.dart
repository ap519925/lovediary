import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lovediary/features/theme/presentation/bloc/theme_bloc.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return IconButton(
          icon: Icon(
            state.themeMode == ThemeMode.dark 
                ? Icons.light_mode 
                : Icons.dark_mode,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () {
            context.read<ThemeBloc>().add(ToggleTheme());
          },
        );
      },
    );
  }
}
