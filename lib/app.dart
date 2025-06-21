import 'package:flutter/material.dart';
import 'package:lovediary/features/auth/presentation/screens/splash_screen.dart';
import 'package:lovediary/features/auth/presentation/screens/login_screen.dart';
import 'package:lovediary/features/auth/presentation/screens/register_screen.dart';
import 'package:lovediary/features/home/presentation/screens/dashboard_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_state.dart';
import 'package:lovediary/features/theme/presentation/bloc/theme_bloc.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp(
          title: 'Love Diary',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.dark,
          ),
          themeMode: themeState.themeMode,
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return const SplashScreen();
            },
          ),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/dashboard': (context) => DashboardScreen(
                  partner1Name: 'User',
                  partner2Name: 'Partner',
                  anniversaryDate: DateTime.now(),
                  distanceApart: 0,
                  nextMeetingDate: DateTime.now().add(const Duration(days: 30)),
                ),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/dashboard') {
              return MaterialPageRoute(
                builder: (context) => DashboardScreen(
                  partner1Name: 'User',
                  partner2Name: 'Partner',
                  anniversaryDate: DateTime.now(),
                  distanceApart: 0,
                  nextMeetingDate: DateTime.now().add(const Duration(days: 30)),
                ),
              );
            }
            return null;
          },
          onUnknownRoute: (settings) {
            // Fallback route
            return MaterialPageRoute(
              builder: (context) => const SplashScreen(),
            );
          },
        );
      },
    );
  }
}
