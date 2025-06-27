import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lovediary/core/utils/date_utils.dart';
import 'package:lovediary/core/utils/logger.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_state.dart';
import 'package:lovediary/features/auth/presentation/screens/login_screen.dart';
import 'package:lovediary/features/auth/presentation/screens/register_screen.dart';
import 'package:lovediary/features/auth/presentation/screens/splash_screen.dart';
import 'package:lovediary/features/home/presentation/screens/dashboard_screen.dart';
import 'package:lovediary/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:lovediary/features/language/presentation/bloc/language_bloc.dart';
import 'package:lovediary/features/language/presentation/bloc/language_state.dart';
import 'package:lovediary/features/profile/presentation/screens/create_post_screen.dart';
import 'package:lovediary/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:lovediary/features/profile/presentation/screens/profile_screen.dart';
import 'package:lovediary/features/settings/presentation/screens/settings_screen.dart';
import 'package:lovediary/features/theme/presentation/bloc/theme_bloc.dart';
import 'package:lovediary/l10n/app_localizations.dart';
import 'package:lovediary/core/localization_wrapper.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return BlocBuilder<LanguageBloc, LanguageState>(
          builder: (context, languageState) {
            return MaterialApp(
              title: 'Love Diary',
              theme: ThemeData(
                primarySwatch: Colors.blueGrey,
                brightness: Brightness.light,
                scaffoldBackgroundColor: Colors.grey[100],
                appBarTheme: AppBarTheme(
                  backgroundColor: Colors.blueGrey,
                  elevation: 0,
                ),
                colorScheme: ColorScheme.light(
                  primary: Colors.blueGrey,
                  secondary: Colors.pinkAccent,
                ),
              ),
              darkTheme: ThemeData(
                primarySwatch: Colors.blueGrey,
                brightness: Brightness.dark,
                scaffoldBackgroundColor: Colors.grey[900],
                appBarTheme: AppBarTheme(
                  backgroundColor: Colors.grey[900],
                  elevation: 0,
                ),
                colorScheme: ColorScheme.dark(
                  primary: Colors.blueGrey[300]!,
                  secondary: Colors.pinkAccent[100]!,
                ),
              ),
              home: BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthUnauthenticated) {
                    // Navigate to login screen when user is logged out
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
                builder: (context, state) {
                  if (state is AuthAuthenticated) {
                    // If user is authenticated, check if we have user data
                    if (state.userData.isNotEmpty) {
                      // Navigate to main screen with user data
                      final profile = state.userData['profile'] as Map<String, dynamic>? ?? {};
                      
                      return MainNavigationScreen(
                        partner1Name: profile['displayName'] as String? ?? 'You',
                        partner2Name: profile['partnerName'] as String? ?? 'Partner',
                        anniversaryDate: profile['anniversaryDate'] != null 
                          ? DateUtil.convertToDateTime(profile['anniversaryDate'])
                          : DateTime.now(),
                        distanceApart: profile['distanceApart'] as double? ?? 0.0,
                        nextMeetingDate: profile['nextMeetingDate'] != null 
                          ? DateUtil.convertToDateTime(profile['nextMeetingDate'])
                          : DateTime.now().add(const Duration(days: 30)),
                        userId: state.user.uid,
                      );
                    }
                  }
                  
                  // Default to splash screen wrapped with localization
                  return const LocalizationWrapper(
                    child: SplashScreen(),
                  );
                },
              ),
              routes: {
                SplashScreen.routeName: (context) => const SplashScreen(),
                '/login': (context) => const LoginScreen(),
                '/register': (context) => const RegisterScreen(),
                '/settings': (context) => const SettingsScreen(),
                ProfileScreen.routeName: (context) => ProfileScreen(
                  userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                ),
                EditProfileScreen.routeName: (context) {
                  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                  return EditProfileScreen(
                    userId: args['userId'] as String,
                    initialProfile: args['initialProfile'] as Map<String, dynamic>,
                  );
                },
                CreatePostScreen.routeName: (context) {
                  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                  return CreatePostScreen(
                    userId: args['userId'] as String,
                  );
                },
                DashboardScreen.routeName: (context) {
                  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                  return DashboardScreen(
                    partner1Name: args['partner1Name'] as String,
                    partner2Name: args['partner2Name'] as String,
                    anniversaryDate: args['anniversaryDate'] as DateTime,
                    distanceApart: args['distanceApart'] as double,
                    nextMeetingDate: args['nextMeetingDate'] as DateTime,
                    partner1Image: args['partner1Image'] as String?,
                    partner2Image: args['partner2Image'] as String?,
                    birthday: args['birthday'] as String?,
                    location: args['location'] as String?,
                  );
                },
                '/main': (context) {
                  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                  return MainNavigationScreen(
                    partner1Name: args['partner1Name'] as String,
                    partner2Name: args['partner2Name'] as String,
                    anniversaryDate: args['anniversaryDate'] as DateTime,
                    distanceApart: args['distanceApart'] as double,
                    nextMeetingDate: args['nextMeetingDate'] as DateTime,
                    userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                  );
                },
              },
              onUnknownRoute: (settings) {
                return MaterialPageRoute(
                  builder: (context) => const SplashScreen(),
                );
              },
              themeMode: themeState.themeMode,
              locale: languageState.locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            );
          },
        );
      },
    );
  }
}
