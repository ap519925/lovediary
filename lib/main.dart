import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lovediary/core/config/firebase_config.dart';
import 'package:lovediary/core/services/error_reporting_service.dart';
import 'package:lovediary/core/services/location_service.dart';
import 'package:lovediary/core/utils/logger.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lovediary/features/language/presentation/bloc/language_bloc.dart';
import 'package:lovediary/features/location/presentation/bloc/location_bloc.dart';
import 'package:lovediary/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:lovediary/features/theme/presentation/bloc/theme_bloc.dart';
import 'package:lovediary/app.dart';

void main() async {
  // Wrap the app in a zone to catch all errors
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase with proper error handling
    await FirebaseConfig.initializeApp();
    
    // Initialize error reporting service
    await ErrorReportingService.initialize();
    
    // Set up logger
    Logger.i('Main', 'Application starting');
    
    // Run the app wrapped in an error boundary
    runApp(
      ErrorBoundary(
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => AuthBloc(
                auth: FirebaseAuth.instance,
                firestore: FirebaseFirestore.instance,
              ),
            ),
            BlocProvider(
              create: (context) => ProfileBloc(
                firestore: FirebaseFirestore.instance,
                storage: FirebaseStorage.instance,
                auth: FirebaseAuth.instance,
              ),
            ),
            BlocProvider(
              create: (context) => ThemeBloc(),
            ),
            BlocProvider(
              create: (context) => LanguageBloc(),
            ),
            BlocProvider(
              create: (context) => LocationBloc(
                locationService: LocationService(),
              ),
            ),
          ],
          child: const App(),
        ),
      ),
    );
  }, (error, stack) {
    // Log fatal errors
    ErrorReportingService.logFatalError(
      error, 
      stack,
      reason: 'Uncaught error in main zone',
    );
  });
}
