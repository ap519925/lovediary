import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:lovediary/core/utils/logger.dart';

/// Utility class for handling shared preferences
class Preferences {
  static const String _tag = 'Preferences';
  static const String _languageKey = 'language_code';
  static const String _themeKey = 'theme_mode';
  
  /// Private constructor to prevent instantiation
  Preferences._();
  
  /// Save the selected language code
  static Future<bool> saveLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setString(_languageKey, languageCode);
      Logger.d(_tag, 'Saved language: $languageCode, result: $result');
      return result;
    } catch (e) {
      Logger.e(_tag, 'Error saving language', e);
      return false;
    }
  }
  
  /// Get the saved language code, or null if not set
  static Future<String?> getLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);
      Logger.d(_tag, 'Retrieved language: $languageCode');
      return languageCode;
    } catch (e) {
      Logger.e(_tag, 'Error getting language', e);
      return null;
    }
  }
  
  /// Save the selected theme mode
  static Future<bool> saveThemeMode(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setInt(_themeKey, themeMode.index);
      Logger.d(_tag, 'Saved theme mode: $themeMode, result: $result');
      return result;
    } catch (e) {
      Logger.e(_tag, 'Error saving theme mode', e);
      return false;
    }
  }
  
  /// Get the saved theme mode, or system if not set
  static Future<ThemeMode> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex = prefs.getInt(_themeKey);
      if (themeModeIndex != null && themeModeIndex >= 0 && themeModeIndex <= 2) {
        final themeMode = ThemeMode.values[themeModeIndex];
        Logger.d(_tag, 'Retrieved theme mode: $themeMode');
        return themeMode;
      }
      return ThemeMode.system;
    } catch (e) {
      Logger.e(_tag, 'Error getting theme mode', e);
      return ThemeMode.system;
    }
  }
  
  /// Clear all preferences
  static Future<bool> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.clear();
      Logger.d(_tag, 'Cleared preferences, result: $result');
      return result;
    } catch (e) {
      Logger.e(_tag, 'Error clearing preferences', e);
      return false;
    }
  }
}
