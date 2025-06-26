import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lovediary/features/language/presentation/bloc/language_bloc.dart';
import 'package:lovediary/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:lovediary/features/theme/presentation/bloc/theme_bloc.dart';
import 'package:lovediary/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBl9HgLgboUCPrf8OS5wbEjcpdLmKsJxxg",
      appId: "1:994710597903:android:fecfe96cc062d39e124e7a",
      messagingSenderId: "994710597903",
      projectId: "love-diary-776dc",
      authDomain: "love-diary-776dc.firebaseapp.com",
      storageBucket: "love-diary-776dc.appspot.com",
    ),
  );
  
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
        BlocProvider(
          create: (context) => LanguageBloc(),
        ),
      ],
      child: const App(),
    ),
  );
}
