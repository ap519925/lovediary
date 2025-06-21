import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lovediary/app.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lovediary/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lovediary/features/auth/presentation/screens/splash_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  final mockAuth = MockFirebaseAuth();
  final mockFirestore = MockFirestore();

  setUpAll(() {
    // Setup mock behavior if needed
  });

  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => AuthBloc(
            auth: mockAuth,
            firestore: mockFirestore,
          )),
        ],
        child: const App(),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
  });

  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => AuthBloc(
            auth: mockAuth,
            firestore: mockFirestore,
          )),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
