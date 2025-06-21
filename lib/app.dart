import 'package:flutter/material.dart';
import 'package:lovediary/features/auth/presentation/screens/splash_screen.dart';
import 'package:lovediary/features/auth/presentation/screens/login_screen.dart';
import 'package:lovediary/features/auth/presentation/screens/register_screen.dart';
import 'package:lovediary/features/home/presentation/screens/dashboard_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_state.dart';
import 'package:lovediary/features/profile/presentation/bloc/profile_bloc.dart'; // Import ProfileBloc
import 'package:lovediary/features/profile/presentation/bloc/profile_event.dart'; // Import ProfileEvent
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
          home: BlocConsumer<AuthBloc, AuthState>( // Use BlocConsumer to listen and build
            listener: (context, authState) {
              if (authState is AuthAuthenticated) {
                // When authenticated, dispatch LoadProfile event for the current user
                context.read<ProfileBloc>().add(LoadProfile(authState.user.uid));
                // Navigate to dashboard if not already there
                if (ModalRoute.of(context)?.settings.name != DashboardScreen.routeName) {
                  Navigator.of(context).pushReplacementNamed(DashboardScreen.routeName);
                }
              } else if (authState is AuthUnauthenticated) {
                // If unauthenticated, navigate to login/splash
                if (ModalRoute.of(context)?.settings.name != LoginScreen.routeName && ModalRoute.of(context)?.settings.name != SplashScreen.routeName) {
                   Navigator.of(context).pushReplacementNamed(SplashScreen.routeName);
                }
              }
            },
            builder: (context, authState) {
              // Initial screen based on auth state
              if (authState is AuthAuthenticated) {
                // Return a placeholder while profile loads, or directly dashboard if profile is loaded elsewhere
                return DashboardScreen(
                  partner1Name: 'User',
                  partner2Name: 'Partner',
                  anniversaryDate: DateTime.now(),
                  distanceApart: 0,
                  nextMeetingDate: DateTime.now().add(const Duration(days: 30)),
                ); 
              } else if (authState is AuthUnauthenticated) {
                return const LoginScreen(); // Or SplashScreen, depending on initial flow
              }
              // Initial state, typically Splash or Login
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
            // Add routes for partner linking screens if they are direct routes
            // '/partner-search': (context) => PartnerSearchScreen(currentUserId: FirebaseAuth.instance.currentUser!.uid),
            // '/partner-link': (context) => PartnerLinkScreen(userId: FirebaseAuth.instance.currentUser!.uid),
          },
          // Removed onGenerateRoute and onUnknownRoute as BlocConsumer handles routing
        );
      },
    );
  }
}
