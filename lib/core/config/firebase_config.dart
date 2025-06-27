import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration utility
class FirebaseConfig {
  /// Private constructor to prevent instantiation
  FirebaseConfig._();
  
  /// Firebase options for different platforms
  static FirebaseOptions get platformOptions {
    // In a real app, these would be stored in environment variables or a secure config file
    // For this example, we're extracting them from the existing code
    
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: "AIzaSyBl9HgLgboUCPrf8OS5wbEjcpdLmKsJxxg",
        appId: "1:994710597903:web:fecfe96cc062d39e124e7a",
        messagingSenderId: "994710597903",
        projectId: "love-diary-776dc",
        authDomain: "love-diary-776dc.firebaseapp.com",
        storageBucket: "love-diary-776dc.appspot.com",
      );
    } else {
      // Default options for Android/iOS
      return const FirebaseOptions(
        apiKey: "AIzaSyBl9HgLgboUCPrf8OS5wbEjcpdLmKsJxxg",
        appId: "1:994710597903:android:fecfe96cc062d39e124e7a",
        messagingSenderId: "994710597903",
        projectId: "love-diary-776dc",
        authDomain: "love-diary-776dc.firebaseapp.com",
        storageBucket: "love-diary-776dc.appspot.com",
      );
    }
  }
  
  /// Initialize Firebase with proper error handling
  static Future<void> initializeApp() async {
    try {
      await Firebase.initializeApp(
        options: platformOptions,
      );
    } catch (e) {
      if (e.toString().contains('duplicate-app')) {
        // Firebase already initialized, continue
        debugPrint('Firebase already initialized');
      } else {
        // Re-throw other errors
        rethrow;
      }
    }
  }
}
