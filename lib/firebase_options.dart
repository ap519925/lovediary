// FlutterFire configuration file
// Generated manually since FlutterFire CLI failed

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBl9HgLgboUCPrf8OS5wbEjcpdLmKsJxxg',
    appId: '1:994710597903:web:3a9f8e7b5e5d5f9c124e7a',
    messagingSenderId: '994710597903',
    projectId: 'love-diary-776dc',
    authDomain: 'love-diary-776dc.firebaseapp.com',
    storageBucket: 'love-diary-776dc.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBl9HgLgboUCPrf8OS5wbEjcpdLmKsJxxg',
    appId: '1:994710597903:android:fecfe96cc062d39e124e7a',
    messagingSenderId: '994710597903',
    projectId: 'love-diary-776dc',
    storageBucket: 'love-diary-776dc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBl9HgLgboUCPrf8OS5wbEjcpdLmKsJxxg',
    appId: '1:994710597903:ios:fecfe96cc062d39e124e7a',
    messagingSenderId: '994710597903',
    projectId: 'love-diary-776dc',
    storageBucket: 'love-diary-776dc.firebasestorage.app',
    iosBundleId: 'love.diary',
  );
}
