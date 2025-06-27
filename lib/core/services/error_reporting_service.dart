import 'dart:async';
import 'dart:io';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lovediary/core/utils/logger.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// A service for reporting errors and crashes
class ErrorReportingService {
  static const String _tag = 'ErrorReportingService';
  static bool _initialized = false;
  static late FirebaseCrashlytics _crashlytics;
  
  /// Initialize the error reporting service
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      Logger.i(_tag, 'Initializing error reporting service');
      
      // Initialize Firebase Crashlytics
      _crashlytics = FirebaseCrashlytics.instance;
      
      // Set user identifiers for better error tracking
      await _setUserIdentifiers();
      
      // Set up error handlers
      _setupErrorHandlers();
      
      _initialized = true;
      Logger.i(_tag, 'Error reporting service initialized');
    } catch (e) {
      Logger.e(_tag, 'Failed to initialize error reporting service', e);
    }
  }
  
  /// Set up error handlers for different types of errors
  static void _setupErrorHandlers() {
    // Handle Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      Logger.e(_tag, 'Flutter error', details.exception, details.stack);
      _crashlytics.recordFlutterError(details);
    };
    
    // Handle Dart errors
    PlatformDispatcher.instance.onError = (error, stack) {
      Logger.e(_tag, 'Platform dispatcher error', error, stack);
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
    
    // Handle zone errors
    runZonedGuarded<Future<void>>(() async {
      // This is where the app would be initialized
    }, (error, stackTrace) {
      Logger.e(_tag, 'Uncaught error in zone', error, stackTrace);
      _crashlytics.recordError(error, stackTrace, fatal: true);
    });
  }
  
  /// Set user identifiers for better error tracking
  static Future<void> _setUserIdentifiers() async {
    try {
      // Get device info
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = 'unknown';
      String deviceModel = 'unknown';
      String osVersion = 'unknown';
      
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        deviceId = webInfo.browserName.name;
        deviceModel = webInfo.platform ?? 'unknown';
        osVersion = webInfo.userAgent ?? 'unknown';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceModel = androidInfo.model;
        osVersion = androidInfo.version.release;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
        deviceModel = iosInfo.model;
        osVersion = iosInfo.systemVersion;
      }
      
      // Get app info
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;
      
      // Set custom keys for better error reports
      await _crashlytics.setCustomKey('device_id', deviceId);
      await _crashlytics.setCustomKey('device_model', deviceModel);
      await _crashlytics.setCustomKey('os_version', osVersion);
      await _crashlytics.setCustomKey('app_version', appVersion);
      await _crashlytics.setCustomKey('build_number', buildNumber);
      
      Logger.d(_tag, 'User identifiers set for error reporting');
    } catch (e) {
      Logger.e(_tag, 'Failed to set user identifiers', e);
    }
  }
  
  /// Set the user ID for error reporting
  static Future<void> setUserId(String userId) async {
    if (!_initialized) await initialize();
    
    try {
      await _crashlytics.setUserIdentifier(userId);
      Logger.d(_tag, 'User ID set for error reporting: $userId');
    } catch (e) {
      Logger.e(_tag, 'Failed to set user ID', e);
    }
  }
  
  /// Log a non-fatal error
  static Future<void> logError(
    dynamic error, 
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? information,
  }) async {
    if (!_initialized) await initialize();
    
    try {
      // Log the error
      Logger.e(_tag, reason ?? 'Error logged', error, stackTrace);
      
      // Add custom information
      if (information != null) {
        for (final entry in information.entries) {
          await _crashlytics.setCustomKey(entry.key, entry.value.toString());
        }
      }
      
      // Record the error
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: false,
      );
    } catch (e) {
      Logger.e(_tag, 'Failed to log error', e);
    }
  }
  
  /// Log a fatal error
  static Future<void> logFatalError(
    dynamic error, 
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? information,
  }) async {
    if (!_initialized) await initialize();
    
    try {
      // Log the error
      Logger.e(_tag, reason ?? 'Fatal error logged', error, stackTrace);
      
      // Add custom information
      if (information != null) {
        for (final entry in information.entries) {
          await _crashlytics.setCustomKey(entry.key, entry.value.toString());
        }
      }
      
      // Record the error
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: true,
      );
    } catch (e) {
      Logger.e(_tag, 'Failed to log fatal error', e);
    }
  }
  
  /// Enable or disable error reporting
  static Future<void> setEnabled(bool enabled) async {
    if (!_initialized) await initialize();
    
    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
      Logger.i(_tag, 'Error reporting ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      Logger.e(_tag, 'Failed to set error reporting enabled state', e);
    }
  }
  
  /// Test error reporting by forcing a crash
  static Future<void> testCrash() async {
    if (!_initialized) await initialize();
    
    try {
      Logger.i(_tag, 'Testing error reporting with a forced crash');
      await _crashlytics.crash();
    } catch (e) {
      Logger.e(_tag, 'Failed to test crash', e);
    }
  }
}

/// A widget that catches errors in the widget tree
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;
  
  const ErrorBoundary({
    Key? key,
    required this.child,
    this.errorBuilder,
  }) : super(key: key);
  
  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _error;
  
  @override
  void initState() {
    super.initState();
    ErrorReportingService.initialize();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(_error!);
    }
    
    return ErrorWidget.builder = (FlutterErrorDetails details) {
      // Report the error
      ErrorReportingService.logError(
        details.exception,
        details.stack,
        reason: 'Widget build error',
        information: {
          'context': details.context.toString(),
          'library': details.library ?? 'unknown',
        },
      );
      
      // Save the error
      _error = details;
      
      // Rebuild with the error builder
      if (mounted) {
        setState(() {});
      }
      
      // Return a default error widget if no error builder is provided
      if (widget.errorBuilder == null) {
        return Material(
          color: Colors.red,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'An error occurred: ${details.exception}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      }
      
      return widget.errorBuilder!(details);
    };
  }
}
