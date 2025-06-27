import 'package:flutter/foundation.dart';

/// Log levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// A simple logger utility for consistent logging across the app
class Logger {

  /// Whether to show debug logs
  static bool showDebugLogs = kDebugMode;

  /// Log a debug message
  static void d(String tag, String message) {
    if (showDebugLogs) {
      _log(LogLevel.debug, tag, message);
    }
  }

  /// Log an info message
  static void i(String tag, String message) {
    _log(LogLevel.info, tag, message);
  }

  /// Log a warning message
  static void w(String tag, String message) {
    _log(LogLevel.warning, tag, message);
  }

  /// Log an error message
  static void e(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.error, tag, message);
    if (error != null) {
      debugPrint('ERROR DETAILS: $error');
      if (stackTrace != null) {
        debugPrint('STACK TRACE: $stackTrace');
      }
    }
  }

  /// Internal logging method
  static void _log(LogLevel level, String tag, String message) {
    final levelStr = level.toString().split('.').last.toUpperCase();
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('[$timestamp] $levelStr/$tag: $message');
  }
}
