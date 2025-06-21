import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import FirebaseMessaging
import 'package:lovediary/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_event.dart';
import 'package:lovediary/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:lovediary/features/theme/presentation/bloc/theme_bloc.dart';
import 'package:lovediary/app.dart';
import 'package:lovediary/firebase_options.dart';

// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
  // You can process the message data here for background tasks
  // For example, if it's a relationship request, you might want to
  // update local state or show a local notification.
  if (message.data['type'] == 'RELATIONSHIP_REQUEST') {
    print('Received background relationship request from: ${message.data['fromUserId']}');
    // Potentially trigger a local notification using flutter_local_notifications
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Messaging handlers
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Request notification permissions (for iOS and Android 13+)
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      // Display a local notification using flutter_local_notifications if desired
      // For example:
      // LocalNotifications.showNotification(
      //   title: message.notification!.title,
      //   body: message.notification!.body,
      //   payload: message.data['type'], // Or other relevant data
      // );
    }
    // Handle foreground logic, e.g., show a snackbar or update UI
    if (message.data['type'] == 'RELATIONSHIP_REQUEST') {
      // This is where you might show a custom in-app banner for a request
      print('Received foreground relationship request from: ${message.data['fromUserId']}');
    }
  });

  // Handle when the app is opened from a terminated state via a notification
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      print('App opened from terminated state by FCM message: ${message.data}');
      // Navigate based on message data if needed
      if (message.data['type'] == 'RELATIONSHIP_REQUEST') {
        // Example: Navigate to the partner requests screen
        // Navigator.of(navigatorKey.currentContext!).pushNamed(
        //   PartnerLinkScreen.routeName,
        //   arguments: message.data['requestId'],
        // );
      }
    }
  });

  // Handle when the app is opened from background by a notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('App opened from background by FCM message: ${message.data}');
    // Navigate based on message data
    if (message.data['type'] == 'RELATIONSHIP_REQUEST') {
      // Example: Navigate to the partner requests screen
      // Navigator.of(navigatorKey.currentContext!).pushNamed(
      //   PartnerLinkScreen.routeName,
      //   arguments: message.data['requestId'],
      // );
    }
  });

  runApp(
    MultiBlocProvider(
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
      ],
      child: const App(),
    ),
  );
}
